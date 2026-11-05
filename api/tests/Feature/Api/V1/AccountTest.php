<?php

declare(strict_types=1);

use App\Models\Note;
use App\Models\User;
use Illuminate\Support\Str;

it('requires a token', function (): void {
    $this->getJson('/api/v1/me')->assertUnauthorized()->assertJsonPath('error.code', 'UNAUTHENTICATED');
});

it('tracks the calling device', function (): void {
    $uuid = (string) Str::uuid();
    $user = signIn(deviceUuid: $uuid);
    $this->withHeader('X-App-Version', '0.1.0+1')->getJson('/api/v1/me')
        ->assertOk()
        ->assertJsonPath('data.devices.0.device_uuid', $uuid)
        ->assertJsonPath('data.devices.0.app_version', '0.1.0+1');
    expect($user->devices()->count())->toBe(1);
});

it('updates name and changes password', function (): void {
    $user = signIn(User::factory()->create(['password' => 'oldpass123']));
    $this->patchJson('/api/v1/me', ['name' => 'Samy'])->assertOk()->assertJsonPath('data.name', 'Samy');

    $this->putJson('/api/v1/me/password', ['current_password' => 'wrong', 'password' => 'newpass123'])
        ->assertStatus(422);
    $this->putJson('/api/v1/me/password', ['current_password' => 'oldpass123', 'password' => 'newpass123'])
        ->assertNoContent();
});

it('stores the wrapped master key with optimistic concurrency', function (): void {
    signIn();
    $this->getJson('/api/v1/me/keys')->assertNotFound();

    $material = ['keyId' => 'k1', 'wrappedDek' => 'abc', 'kdf' => ['salt' => 'x']];
    $this->putJson('/api/v1/me/keys', ['key_material' => $material, 'expected_key_version' => 0])
        ->assertOk()->assertJsonPath('data.key_version', 1);

    // A second device still thinking version 0 must not overwrite it.
    $this->putJson('/api/v1/me/keys', ['key_material' => $material, 'expected_key_version' => 0])
        ->assertStatus(409)->assertJsonPath('error.code', 'CONFLICT');

    $this->getJson('/api/v1/me/keys')
        ->assertOk()
        ->assertJsonPath('data.key_material.keyId', 'k1')
        ->assertJsonPath('data.key_version', 1);
});

it('deletes the account and every note (password check)', function (): void {
    $user = signIn(User::factory()->create(['password' => 'secret123']));
    $this->postJson('/api/v1/sync/push', ['changes' => [noteChange((string) Str::uuid(), 0)]])->assertOk();

    $this->deleteJson('/api/v1/me', ['password' => 'wrong'])->assertStatus(422);
    $this->deleteJson('/api/v1/me', ['password' => 'secret123'])->assertNoContent();

    expect(User::query()->find($user->id))->toBeNull()
        ->and(Note::query()->count())->toBe(0);
});

it('google-only accounts confirm deletion with a fresh google token', function (): void {
    fakeGoogle();
    $user = User::factory()->create(['password' => null, 'google_id' => 'sub-1']);
    signIn($user);
    $this->deleteJson('/api/v1/me', ['id_token' => 'good:other:x@example.com'])->assertStatus(422);
    $this->deleteJson('/api/v1/me', ['id_token' => 'good:sub-1:x@example.com'])->assertNoContent();
});

it('revokes a device', function (): void {
    $uuid = (string) Str::uuid();
    $user = User::factory()->create();
    $user->createToken($uuid);
    signIn($user, $uuid);
    $this->getJson('/api/v1/me')->assertOk();

    $this->deleteJson("/api/v1/devices/{$uuid}")->assertNoContent();
    expect($user->tokens()->count())->toBe(0)->and($user->devices()->count())->toBe(0);
    $this->deleteJson('/api/v1/devices/'.Str::uuid())->assertNotFound();
});
