<?php

declare(strict_types=1);

namespace App\Services;

use App\Contracts\GoogleIdentity;
use App\Contracts\GoogleIdTokenVerifier;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Verifies a Google ID token with Google's tokeninfo endpoint and checks
 * the audience against our OAuth client IDs (config/services.php).
 */
final class HttpGoogleIdTokenVerifier implements GoogleIdTokenVerifier
{
    /** @param list<string> $clientIds */
    public function __construct(private readonly array $clientIds) {}

    public function verify(string $idToken): ?GoogleIdentity
    {
        if ($this->clientIds === []) {
            return null; // Google sign-in not configured
        }
        try {
            $response = Http::timeout(5)->get('https://oauth2.googleapis.com/tokeninfo', ['id_token' => $idToken]);
        } catch (Throwable) {
            return null;
        }
        if (! $response->ok()) {
            return null;
        }
        $claims = $response->json();
        if (! is_array($claims)
            || ! in_array($claims['aud'] ?? null, $this->clientIds, true)
            || ! in_array($claims['iss'] ?? null, ['accounts.google.com', 'https://accounts.google.com'], true)
            || (int) ($claims['exp'] ?? 0) < time()
            || ! isset($claims['sub'], $claims['email'])) {
            return null;
        }

        return new GoogleIdentity(
            sub: (string) $claims['sub'],
            email: strtolower((string) $claims['email']),
            emailVerified: ($claims['email_verified'] ?? 'false') === 'true' || ($claims['email_verified'] ?? false) === true,
            name: isset($claims['name']) ? (string) $claims['name'] : null,
        );
    }
}
