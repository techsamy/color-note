<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Contracts\GoogleIdTokenVerifier;
use App\Http\Controllers\Controller;
use App\Http\Requests\V1\DeviceRequest;
use App\Http\Requests\V1\GoogleLoginRequest;
use App\Http\Requests\V1\LoginRequest;
use App\Http\Requests\V1\RegisterRequest;
use App\Http\Resources\V1\UserResource;
use App\Models\User;
use App\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

final class AuthController extends Controller
{
    public function __construct(private readonly AuthService $auth) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::query()->create([
            'email' => $request->string('email')->toString(),
            'password' => $request->string('password')->toString(),
            'name' => $request->input('name'),
        ]);

        return $this->tokenResponse($request, $user, isNew: true, status: 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        /** @var User|null $user */
        $user = User::query()->where('email', $request->string('email')->toString())->first();
        if ($user === null || $user->password === null || ! Hash::check($request->string('password')->toString(), $user->password)) {
            throw ValidationException::withMessages(['email' => ['These credentials do not match our records.']]);
        }

        return $this->tokenResponse($request, $user, isNew: false);
    }

    public function google(GoogleLoginRequest $request, GoogleIdTokenVerifier $verifier): JsonResponse
    {
        $identity = $verifier->verify($request->string('id_token')->toString());
        if ($identity === null) {
            throw ValidationException::withMessages(['id_token' => ['Google sign-in failed.']]);
        }

        $user = User::query()->where('google_id', $identity->sub)->first();
        $isNew = false;
        if ($user === null) {
            $user = User::query()->where('email', $identity->email)->first();
            if ($user !== null) {
                // Link an existing email account only if Google verified the email.
                if (! $identity->emailVerified) {
                    throw ValidationException::withMessages(['id_token' => ['Google email is not verified.']]);
                }
                $user->google_id = $identity->sub;
                $user->email_verified_at ??= now();
                $user->save();
            } else {
                $user = User::query()->create([
                    'email' => $identity->email,
                    'name' => $identity->name,
                    'google_id' => $identity->sub,
                ]);
                if ($identity->emailVerified) {
                    $user->forceFill(['email_verified_at' => now()])->save();
                }
                $isNew = true;
            }
        }

        return $this->tokenResponse($request, $user, isNew: $isNew, status: $isNew ? 201 : 200);
    }

    public function logout(Request $request): Response
    {
        $token = $request->user()?->currentAccessToken();
        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }

        return response()->noContent();
    }

    /** Always 204 so the endpoint can't be used to discover accounts. */
    public function forgotPassword(Request $request): Response
    {
        $request->validate(['email' => ['required', 'email']]);
        Password::sendResetLink(['email' => strtolower(trim((string) $request->input('email')))]);

        return response()->noContent();
    }

    public function resetPassword(Request $request): Response
    {
        $request->validate([
            'email' => ['required', 'email'],
            'token' => ['required', 'string'],
            'password' => ['required', 'string', PasswordRule::min(8)],
        ]);
        $status = Password::reset(
            [
                'email' => strtolower(trim((string) $request->input('email'))),
                'token' => (string) $request->input('token'),
                'password' => (string) $request->input('password'),
            ],
            function (User $user, string $password): void {
                $user->password = $password;
                $user->save();
                $user->tokens()->delete(); // sign out everywhere
            },
        );
        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['token' => ['This reset link is invalid or has expired.']]);
        }

        return response()->noContent();
    }

    private function tokenResponse(DeviceRequest $request, User $user, bool $isNew, int $status = 200): JsonResponse
    {
        $issued = $this->auth->issueToken(
            $user,
            $request->string('device_uuid')->toString(),
            $request->input('device_name'),
            $request->input('platform'),
            $request->header('X-App-Version'),
        );

        return response()->json([
            'data' => [
                'token' => $issued['token'],
                'user' => new UserResource($user->refresh()),
                'is_new' => $isNew,
            ],
        ], $status);
    }
}
