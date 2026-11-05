<?php

declare(strict_types=1);

use App\Contracts\GoogleIdentity;
use App\Contracts\GoogleIdTokenVerifier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

pest()->extend(TestCase::class)
    ->use(RefreshDatabase::class)
    ->in('Feature');

/** Acts as a signed-in user on a known device. */
function signIn(?User $user = null, ?string $deviceUuid = null): User
{
    $user ??= User::factory()->create();
    Sanctum::actingAs($user);
    test()->withHeader('X-Device-Id', $deviceUuid ?? (string) Str::uuid());

    return $user;
}

/** Replaces Google verification: token "good:<sub>:<email>" is valid. */
function fakeGoogle(bool $emailVerified = true): void
{
    app()->instance(GoogleIdTokenVerifier::class, new class($emailVerified) implements GoogleIdTokenVerifier
    {
        public function __construct(private readonly bool $verified) {}

        public function verify(string $idToken): ?GoogleIdentity
        {
            $parts = explode(':', $idToken);
            if (count($parts) !== 3 || $parts[0] !== 'good') {
                return null;
            }

            return new GoogleIdentity($parts[1], $parts[2], $this->verified, 'Google User');
        }
    });
}

/**
 * A valid flat note payload for sync.
 *
 * @param  array<string, mixed>  $overrides
 * @return array<string, mixed>
 */
function noteData(array $overrides = []): array
{
    return [
        'type' => 0,
        'title' => 'Title',
        'body' => 'Body',
        'color' => 2,
        'is_pinned' => false,
        'is_archived' => false,
        'is_locked' => false,
        'crypto_meta' => null,
        'reminder_at' => null,
        'reminder_rule' => null,
        'reminder_all_day' => false,
        'status_bar_pinned' => false,
        'calendar_date' => null,
        'created_at' => 1_730_800_000_000,
        'updated_at' => 1_730_800_500_000,
        'deleted_at' => null,
        ...$overrides,
    ];
}

/**
 * @param  array<string, mixed>  $data
 * @return array<string, mixed>
 */
function noteChange(string $id, int $baseVersion, array $data = []): array
{
    return ['entity' => 'note', 'id' => $id, 'base_version' => $baseVersion, 'data' => noteData($data)];
}
