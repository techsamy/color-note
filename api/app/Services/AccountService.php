<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;

/**
 * Account operations shared by the API (app) and the website, so both
 * paths delete / reset in exactly the same way.
 */
final class AccountService
{
    /** Deletes the account and all server data (FR-B6, Play policy). */
    public function delete(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $user->tokens()->delete();
            // FK cascades remove devices, notes, memberships, feed, labels.
            $user->delete();
        });
    }

    /**
     * Finds an email/password account. Returns null for an unknown email,
     * a Google-only account or a wrong password — callers must not tell
     * these apart (no account enumeration).
     */
    public function findByCredentials(string $email, string $password): ?User
    {
        $user = User::query()->where('email', self::normaliseEmail($email))->first();
        if ($user === null || $user->password === null || ! Hash::check($password, $user->password)) {
            return null;
        }

        return $user;
    }

    /** Returns false when the token is invalid or expired. Signs out every device on success. */
    public function resetPassword(string $email, string $token, string $password): bool
    {
        $status = Password::reset(
            ['email' => self::normaliseEmail($email), 'token' => $token, 'password' => $password],
            function (User $user, string $password): void {
                $user->password = $password;
                $user->save();
                $user->tokens()->delete();
            },
        );

        return $status === Password::PASSWORD_RESET;
    }

    public static function normaliseEmail(string $email): string
    {
        return strtolower(trim($email));
    }
}
