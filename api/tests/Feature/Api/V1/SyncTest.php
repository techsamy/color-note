<?php

declare(strict_types=1);

use App\Models\Note;
use App\Models\NoteMember;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;

function push(array ...$changes): TestResponse
{
    return test()->postJson('/api/v1/sync/push', ['changes' => $changes]);
}

function pull(int $cursor = 0, int $limit = 500): TestResponse
{
    return test()->getJson("/api/v1/sync/pull?cursor={$cursor}&limit={$limit}");
}

it('creates a note and pulls it back as one flat object', function (): void {
    signIn();
    $id = (string) Str::uuid();
    push(noteChange($id, 0, ['title' => 'Hello', 'color' => 4, 'is_pinned' => true]))
        ->assertOk()
        ->assertJsonPath('data.results.0', ['id' => $id, 'status' => 'applied', 'version' => 1]);

    pull()->assertOk()
        ->assertJsonPath('meta.next_cursor', 1)
        ->assertJsonPath('meta.has_more', false)
        ->assertJsonPath('data.changes.0.id', $id)
        ->assertJsonPath('data.changes.0.version', 1)
        ->assertJsonPath('data.changes.0.my_permission', 0)
        ->assertJsonPath('data.changes.0.data.title', 'Hello')
        ->assertJsonPath('data.changes.0.data.color', 4)
        ->assertJsonPath('data.changes.0.data.is_pinned', true);
});

it('new device gets everything with cursor 0 (FR-B9)', function (): void {
    $user = signIn();
    foreach (range(1, 3) as $i) {
        push(noteChange((string) Str::uuid(), 0, ['title' => "n{$i}"]))->assertOk();
    }
    signIn($user); // another device
    pull()->assertOk()->assertJsonCount(3, 'data.changes');
});

it('updates with the right base version; stale base is a conflict', function (): void {
    signIn();
    $id = (string) Str::uuid();
    push(noteChange($id, 0, ['title' => 'v1']));
    push(noteChange($id, 1, ['title' => 'v2']))->assertJsonPath('data.results.0.version', 2);

    // Another device edited from version 1 → conflict with server copy.
    push(noteChange($id, 1, ['title' => 'offline edit']))
        ->assertJsonPath('data.results.0.status', 'conflict')
        ->assertJsonPath('data.results.0.server.version', 2)
        ->assertJsonPath('data.results.0.server.data.title', 'v2');
    expect(Note::query()->find($id)?->title)->toBe('v2');
});

it('one bad record never fails the batch', function (): void {
    signIn();
    $good = (string) Str::uuid();
    push(
        noteChange((string) Str::uuid(), 0, ['color' => 'red']),
        noteChange($good, 0),
        ['entity' => 'spaceship', 'id' => 'x', 'base_version' => 0, 'data' => ['a' => 1]],
    )->assertOk()
        ->assertJsonPath('data.results.0.status', 'rejected')
        ->assertJsonPath('data.results.0.error.code', 'VALIDATION_FAILED')
        ->assertJsonPath('data.results.1.status', 'applied')
        ->assertJsonPath('data.results.2.error.code', 'UNKNOWN_ENTITY');
});

it('cannot touch another user\'s note', function (): void {
    signIn();
    $id = (string) Str::uuid();
    push(noteChange($id, 0, ['title' => 'mine']));

    signIn(User::factory()->create());
    push(noteChange($id, 1, ['title' => 'hijack']))
        ->assertJsonPath('data.results.0.status', 'rejected')
        ->assertJsonPath('data.results.0.error.code', 'FORBIDDEN');
    pull()->assertJsonCount(0, 'data.changes');
    expect(Note::query()->find($id)?->title)->toBe('mine');
});

it('viewers are read-only (sharing-ready)', function (): void {
    signIn();
    $id = (string) Str::uuid();
    push(noteChange($id, 0));
    $viewer = User::factory()->create();
    NoteMember::query()->create([
        'note_id' => $id, 'user_id' => $viewer->id,
        'permission' => NoteMember::PERMISSION_VIEWER, 'status' => NoteMember::STATUS_ACTIVE,
    ]);

    signIn($viewer);
    push(noteChange($id, 1, ['title' => 'nope']))->assertJsonPath('data.results.0.error.code', 'READ_ONLY');
});

it('fans changes out to every active member\'s feed', function (): void {
    $owner = signIn();
    $id = (string) Str::uuid();
    push(noteChange($id, 0));
    $editor = User::factory()->create();
    NoteMember::query()->create([
        'note_id' => $id, 'user_id' => $editor->id, 'color' => 7,
        'permission' => NoteMember::PERMISSION_EDITOR, 'status' => NoteMember::STATUS_ACTIVE,
    ]);

    push(noteChange($id, 1, ['title' => 'shared edit', 'color' => 1]))->assertJsonPath('data.results.0.status', 'applied');

    signIn($editor);
    // Shared title arrives; colour stays the editor's own.
    pull()->assertJsonPath('data.changes.0.data.title', 'shared edit')
        ->assertJsonPath('data.changes.0.data.color', 7)
        ->assertJsonPath('data.changes.0.my_permission', 1);
    expect($owner->refresh()->feed_seq)->toBe(2);
});

it('paginates the feed and dedupes repeated edits', function (): void {
    signIn();
    $a = (string) Str::uuid();
    $b = (string) Str::uuid();
    push(noteChange($a, 0));
    push(noteChange($a, 1, ['title' => 'a2']));
    push(noteChange($b, 0));

    $page1 = pull(0, 2)->assertJsonPath('meta.has_more', true)->assertJsonPath('meta.next_cursor', 2);
    expect($page1->json('data.changes'))->toHaveCount(1); // a twice -> once, latest state
    expect($page1->json('data.changes.0.data.title'))->toBe('a2');

    pull(2, 2)->assertJsonPath('meta.has_more', false)
        ->assertJsonPath('meta.next_cursor', 3)
        ->assertJsonPath('data.changes.0.id', $b);
    pull(3)->assertJsonCount(0, 'data.changes')->assertJsonPath('meta.next_cursor', 3);
});

it('trash is a tombstone; purge wipes content but keeps the tombstone', function (): void {
    signIn();
    $id = (string) Str::uuid();
    push(noteChange($id, 0, ['title' => 'secret stuff']));
    push(noteChange($id, 1, ['deleted_at' => 1_730_900_000_000]))->assertJsonPath('data.results.0.version', 2);
    push(noteChange($id, 2, ['deleted_at' => 1_730_900_000_000, 'purged' => true]))->assertJsonPath('data.results.0.status', 'applied');

    $note = Note::query()->findOrFail($id);
    expect($note->purged)->toBeTrue()->and($note->title)->toBe('')->and($note->body)->toBe('');
    pull()->assertJsonPath('data.changes.0.data.purged', true);

    // Late edit from an offline device can't resurrect it.
    push(noteChange($id, 3, ['title' => 'zombie']))->assertJsonPath('data.results.0.status', 'conflict');
});

it('stores locked notes as opaque ciphertext', function (): void {
    signIn();
    $id = (string) Str::uuid();
    $meta = ['v' => 1, 'alg' => 'aes-256-gcm', 'nonce' => 'bm9uY2U=', 'keyId' => 'k1'];
    push(noteChange($id, 0, ['is_locked' => true, 'title' => '', 'body' => 'Q0lQSEVS', 'crypto_meta' => $meta]))
        ->assertJsonPath('data.results.0.status', 'applied');
    pull()->assertJsonPath('data.changes.0.data.body', 'Q0lQSEVS')
        ->assertJsonPath('data.changes.0.data.crypto_meta.keyId', 'k1');

    // Locked without metadata is invalid.
    push(noteChange((string) Str::uuid(), 0, ['is_locked' => true, 'crypto_meta' => null]))
        ->assertJsonPath('data.results.0.status', 'rejected');
});

it('syncs colour labels with versions', function (): void {
    signIn();
    push(['entity' => 'color_label', 'id' => '0', 'base_version' => 0, 'data' => ['label' => 'Work']])
        ->assertJsonPath('data.results.0.version', 1);
    push(['entity' => 'color_label', 'id' => '0', 'base_version' => 0, 'data' => ['label' => 'Other']])
        ->assertJsonPath('data.results.0.status', 'conflict')
        ->assertJsonPath('data.results.0.server.data.label', 'Work');
    pull()->assertJsonPath('data.changes.0.entity', 'color_label')
        ->assertJsonPath('data.changes.0.data.label', 'Work');
});

it('validates the push envelope', function (): void {
    signIn();
    $this->postJson('/api/v1/sync/push', ['changes' => array_fill(0, 201, noteChange('x', 0))])
        ->assertStatus(422);
    $this->postJson('/api/v1/sync/push', ['changes' => [['entity' => 'note']]])->assertStatus(422);
});
