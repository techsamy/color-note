<?php

declare(strict_types=1);

use App\Models\User;
use Illuminate\Support\Str;

function device(): array
{
    return ['device_uuid' => (string) Str::uuid(), 'device_name' => 'Pixel 7', 'platform' => 'android'];
}

it('registers and returns a token that works', function (): void {
    $res = $this->postJson('/api/v1/auth/register', [
        'email' => '  New@Example.com ',
        'password' => 'secret123',
        ...device(),
    ])->assertCreated()
        ->assertJsonPath('data.user.email', 'new@example.com')
        ->assertJsonPath('data.user.has_password', true)
        ->assertJsonPath('data.is_new', true);

    $this->withToken($res->json('data.token'))
        ->getJson('/api/v1/me')
        ->assertOk()
        ->assertJsonPath('data.user.email', 'new@example.com')
        ->assertJsonCount(1, 'data.devices');
});

it('rejects duplicate email and weak passwords', function (): void {
    User::factory()->create(['email' => 'taken@example.com']);
    $this->postJson('/api/v1/auth/register', ['email' => 'taken@example.com', 'password' => 'short', ...device()])
        ->assertStatus(422)
        ->assertJsonPath('error.code', 'VALIDATION_FAILED')
        ->assertJsonStructure(['error' => ['fields' => ['email', 'password']]]);
});

it('logs in; wrong password gives a generic error', function (): void {
    User::factory()->create(['email' => 'a@example.com', 'password' => 'secret123']);

    $this->postJson('/api/v1/auth/login', ['email' => 'A@example.com', 'password' => 'secret123', ...device()])
        ->assertOk()
        ->assertJsonPath('data.is_new', false);

    $this->postJson('/api/v1/auth/login', ['email' => 'a@example.com', 'password' => 'nope', ...device()])
        ->assertStatus(422)
        ->assertJsonPath('error.fields.email.0', 'These credentials do not match our records.');
});

it('signing in again on the same device replaces its token', function (): void {
    $user = User::factory()->create(['email' => 'a@example.com', 'password' => 'secret123']);
    $dev = device();
    $first = $this->postJson('/api/v1/auth/login', ['email' => 'a@example.com', 'password' => 'secret123', ...$dev])->json('data.token');
    $this->postJson('/api/v1/auth/login', ['email' => 'a@example.com', 'password' => 'secret123', ...$dev]);

    expect($user->tokens()->count())->toBe(1);
    $this->app['auth']->forgetGuards();
    $this->withToken($first)->getJson('/api/v1/me')->assertUnauthorized();
});

it('logout revokes the current token', function (): void {
    $token = $this->postJson('/api/v1/auth/register', ['email' => 'b@example.com', 'password' => 'secret123', ...device()])->json('data.token');
    $this->withToken($token)->postJson('/api/v1/auth/logout')->assertNoContent();
    $this->app['auth']->forgetGuards();
    $this->withToken($token)->getJson('/api/v1/me')->assertUnauthorized();
});

it('google sign-in creates, then reuses, the account', function (): void {
    fakeGoogle();
    $this->postJson('/api/v1/auth/google', ['id_token' => 'good:sub-1:g@example.com', ...device()])
        ->assertCreated()
        ->assertJsonPath('data.is_new', true)
        ->assertJsonPath('data.user.google_linked', true)
        ->assertJsonPath('data.user.has_password', false);

    $this->postJson('/api/v1/auth/google', ['id_token' => 'good:sub-1:g@example.com', ...device()])
        ->assertOk()
        ->assertJsonPath('data.is_new', false);
    expect(User::query()->count())->toBe(1);
});

it('google sign-in links a verified email to an existing account', function (): void {
    fakeGoogle();
    $user = User::factory()->create(['email' => 'g@example.com']);
    $this->postJson('/api/v1/auth/google', ['id_token' => 'good:sub-9:g@example.com', ...device()])->assertOk();
    expect($user->refresh()->google_id)->toBe('sub-9');
});

it('google sign-in refuses to link an unverified email', function (): void {
    fakeGoogle(emailVerified: false);
    User::factory()->create(['email' => 'g@example.com']);
    $this->postJson('/api/v1/auth/google', ['id_token' => 'good:sub-9:g@example.com', ...device()])->assertStatus(422);
});

it('rejects invalid google tokens', function (): void {
    fakeGoogle();
    $this->postJson('/api/v1/auth/google', ['id_token' => 'forged', ...device()])
        ->assertStatus(422)
        ->assertJsonPath('error.fields.id_token.0', 'Google sign-in failed.');
});

it('forgot password never reveals whether an account exists', function (): void {
    $this->postJson('/api/v1/auth/password/forgot', ['email' => 'nobody@example.com'])->assertNoContent();
});

it('blocks apps below the minimum version', function (): void {
    config()->set('huenote.min_supported_version', '1.2.0');
    $this->withHeader('X-App-Version', '1.1.9+40')
        ->postJson('/api/v1/auth/login', ['email' => 'a@example.com', 'password' => 'x', ...device()])
        ->assertStatus(426)
        ->assertJsonPath('error.code', 'APP_UPGRADE_REQUIRED');
});

it('rate-limits auth attempts', function (): void {
    foreach (range(1, 10) as $_) {
        $this->postJson('/api/v1/auth/login', ['email' => 'x@example.com', 'password' => 'x', ...device()]);
    }
    $this->postJson('/api/v1/auth/login', ['email' => 'x@example.com', 'password' => 'x', ...device()])
        ->assertStatus(429)
        ->assertJsonPath('error.code', 'RATE_LIMITED');
});
