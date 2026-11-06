<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Contracts\GoogleIdTokenVerifier;
use App\Http\Controllers\Controller;
use App\Http\Requests\V1\KeysRequest;
use App\Http\Resources\V1\DeviceResource;
use App\Http\Resources\V1\UserResource;
use App\Models\User;
use App\Services\AccountService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;

final class AccountController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $this->user($request);

        return response()->json(['data' => [
            'user' => new UserResource($user),
            'devices' => DeviceResource::collection($user->devices()->orderByDesc('last_seen_at')->get()),
        ]]);
    }

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate(['name' => ['nullable', 'string', 'max:100']]);
        $user = $this->user($request);
        $user->name = $data['name'] ?? null;
        $user->save();

        return response()->json(['data' => new UserResource($user)]);
    }

    public function changePassword(Request $request): Response
    {
        $user = $this->user($request);
        $request->validate([
            'current_password' => [$user->password === null ? 'nullable' : 'required', 'string'],
            'password' => ['required', 'string', PasswordRule::min(8)],
        ]);
        if ($user->password !== null && ! Hash::check((string) $request->input('current_password'), $user->password)) {
            throw ValidationException::withMessages(['current_password' => ['The current password is incorrect.']]);
        }
        $user->password = (string) $request->input('password');
        $user->save();
        // Keep this device signed in, sign out the others.
        $current = $request->user()?->currentAccessToken();
        $user->tokens()->when($current !== null, fn ($q) => $q->whereKeyNot($current->getKey()))->delete();

        return response()->noContent();
    }

    /**
     * Deletes the account and all server data (Play policy). Requires the
     * password, or a fresh Google ID token for Google-only accounts.
     */
    public function destroy(Request $request, GoogleIdTokenVerifier $verifier, AccountService $accounts): Response
    {
        $user = $this->user($request);
        if ($user->password !== null) {
            $request->validate(['password' => ['required', 'string']]);
            if (! Hash::check((string) $request->input('password'), $user->password)) {
                throw ValidationException::withMessages(['password' => ['The password is incorrect.']]);
            }
        } else {
            $request->validate(['id_token' => ['required', 'string']]);
            $identity = $verifier->verify((string) $request->input('id_token'));
            if ($identity === null || $identity->sub !== $user->google_id) {
                throw ValidationException::withMessages(['id_token' => ['Please sign in with Google again.']]);
            }
        }

        $accounts->delete($user);

        return response()->noContent();
    }

    public function keys(Request $request): JsonResponse
    {
        // Fresh read: another device may have just replaced the key.
        $user = User::query()->findOrFail($this->user($request)->id);
        if ($user->key_material === null) {
            abort(404, 'No master key yet.');
        }

        return response()->json(['data' => [
            'key_material' => $user->key_material,
            'key_version' => $user->key_version,
        ]]);
    }

    /** Optimistic concurrency: another device may have changed the key. */
    public function updateKeys(KeysRequest $request): JsonResponse
    {
        $userId = $this->user($request)->id;

        return DB::transaction(function () use ($request, $userId): JsonResponse {
            /** @var User $user */
            $user = User::query()->lockForUpdate()->findOrFail($userId);
            if ($user->key_version !== $request->integer('expected_key_version')) {
                abort(409, 'The master key was changed on another device.');
            }
            $user->key_material = (array) $request->input('key_material');
            $user->key_version++;
            $user->save();

            return response()->json(['data' => ['key_version' => $user->key_version]]);
        });
    }

    public function destroyDevice(Request $request, string $deviceUuid): Response
    {
        $user = $this->user($request);
        $device = $user->devices()->where('device_uuid', $deviceUuid)->firstOrFail();
        $user->tokens()->where('name', $deviceUuid)->delete();
        $device->delete();

        return response()->noContent();
    }

    private function user(Request $request): User
    {
        $user = $request->user();
        abort_unless($user instanceof User, 401);

        return $user;
    }
}
