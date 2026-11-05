<?php

declare(strict_types=1);

namespace App\Contracts;

final class GoogleIdentity
{
    public function __construct(
        public readonly string $sub,
        public readonly string $email,
        public readonly bool $emailVerified,
        public readonly ?string $name,
    ) {}
}

interface GoogleIdTokenVerifier
{
    /** Returns null when the token is invalid, expired or for another app. */
    public function verify(string $idToken): ?GoogleIdentity;
}
