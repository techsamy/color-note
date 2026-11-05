<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\ColorLabel;
use App\Models\Device;
use App\Models\Note;
use App\Models\NoteMember;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * Revision-based sync with conflict copies (ADR 0004, docs/03 §3.3).
 * Conflicts are per record, never per request.
 */
final class SyncService
{
    public function __construct(private readonly FeedService $feed) {}

    /**
     * @param  list<array<string, mixed>>  $changes
     * @return list<array<string, mixed>>
     */
    public function push(User $user, ?Device $device, array $changes): array
    {
        $results = [];
        foreach ($changes as $change) {
            $results[] = match ($change['entity']) {
                'note' => $this->pushNote($user, $device, $change),
                'color_label' => $this->pushColorLabel($user, $change),
                // Unknown entity from a newer app: reject, never fail the batch.
                default => $this->rejected((string) $change['id'], 'UNKNOWN_ENTITY'),
            };
        }

        return $results;
    }

    /**
     * @param  array<string, mixed>  $change
     * @return array<string, mixed>
     */
    private function pushNote(User $user, ?Device $device, array $change): array
    {
        $id = (string) $change['id'];
        $data = (array) $change['data'];
        $validator = Validator::make($data, [
            'type' => ['required', 'integer', 'between:0,255'],
            'title' => ['present', 'nullable', 'string', 'max:2000'],
            'body' => ['present', 'nullable', 'string', 'max:1000000'],
            'color' => ['required', 'integer', 'between:0,255'],
            'is_pinned' => ['required', 'boolean'],
            'is_archived' => ['required', 'boolean'],
            'is_locked' => ['required', 'boolean'],
            'crypto_meta' => ['nullable', 'array', 'required_if_accepted:is_locked'],
            'reminder_at' => ['nullable', 'integer'],
            'reminder_rule' => ['nullable', 'array'],
            'reminder_all_day' => ['sometimes', 'boolean'],
            'status_bar_pinned' => ['sometimes', 'boolean'],
            'calendar_date' => ['nullable', 'date_format:Y-m-d'],
            'created_at' => ['required', 'integer', 'min:0'],
            'updated_at' => ['required', 'integer', 'min:0'],
            'deleted_at' => ['nullable', 'integer', 'min:0'],
            'purged' => ['sometimes', 'boolean'],
        ]);
        if ($validator->fails()) {
            return $this->rejected($id, 'VALIDATION_FAILED', $validator->errors()->toArray());
        }
        $baseVersion = (int) $change['base_version'];

        return DB::transaction(function () use ($user, $device, $id, $data, $baseVersion): array {
            /** @var Note|null $note */
            $note = Note::query()->lockForUpdate()->find($id);

            if ($note === null) {
                $note = new Note(['id' => $id, 'owner_id' => $user->id, 'version' => 1]);
                $this->fillShared($note, $data, $device);
                $note->save();
                $member = new NoteMember([
                    'note_id' => $id,
                    'user_id' => $user->id,
                    'permission' => NoteMember::PERMISSION_OWNER,
                    'status' => NoteMember::STATUS_ACTIVE,
                ]);
                $this->fillPersonal($member, $data);
                $member->save();
                $this->feed->append([$user->id], 'note', $id);

                return ['id' => $id, 'status' => 'applied', 'version' => $note->version];
            }

            /** @var NoteMember|null $member */
            $member = $note->members()
                ->where('user_id', $user->id)
                ->where('status', NoteMember::STATUS_ACTIVE)
                ->first();
            if ($member === null) {
                return $this->rejected($id, 'FORBIDDEN');
            }
            if ($member->permission === NoteMember::PERMISSION_VIEWER) {
                return $this->rejected($id, 'READ_ONLY');
            }
            if ($note->purged) {
                // Deleted forever elsewhere: nothing to merge into.
                return ['id' => $id, 'status' => 'conflict', 'server' => NotePresenter::change($note, $member)];
            }
            if ($note->version !== $baseVersion) {
                return ['id' => $id, 'status' => 'conflict', 'server' => NotePresenter::change($note, $member)];
            }

            $this->fillShared($note, $data, $device);
            $note->version++;
            $note->save();
            $this->fillPersonal($member, $data);
            $member->save();

            $memberIds = $note->members()
                ->where('status', NoteMember::STATUS_ACTIVE)
                ->pluck('user_id')
                ->all();
            $this->feed->append(array_map('intval', $memberIds), 'note', $id);

            return ['id' => $id, 'status' => 'applied', 'version' => $note->version];
        });
    }

    /** @param array<string, mixed> $data */
    private function fillShared(Note $note, array $data, ?Device $device): void
    {
        $purged = (bool) ($data['purged'] ?? false);
        $note->fill([
            'type' => (int) $data['type'],
            // Purged = content wiped; only the tombstone remains.
            'title' => $purged ? '' : (string) ($data['title'] ?? ''),
            'body' => $purged ? '' : (string) ($data['body'] ?? ''),
            'is_locked' => $purged ? false : (bool) $data['is_locked'],
            'crypto_meta' => $purged ? null : ($data['crypto_meta'] ?? null),
            'calendar_date' => $data['calendar_date'] ?? null,
            'client_created_at' => (int) $data['created_at'],
            'client_updated_at' => (int) $data['updated_at'],
            'deleted_at' => $purged ? (int) ($data['deleted_at'] ?? $data['updated_at']) : ($data['deleted_at'] ?? null),
            'purged' => $purged,
            'updated_by_device_id' => $device?->id,
        ]);
    }

    /** @param array<string, mixed> $data */
    private function fillPersonal(NoteMember $member, array $data): void
    {
        $member->fill([
            'color' => (int) $data['color'],
            'is_pinned' => (bool) $data['is_pinned'],
            'is_archived' => (bool) $data['is_archived'],
            'reminder_at' => $data['reminder_at'] ?? null,
            'reminder_rule' => $data['reminder_rule'] ?? null,
            'reminder_all_day' => (bool) ($data['reminder_all_day'] ?? false),
            'status_bar_pinned' => (bool) ($data['status_bar_pinned'] ?? false),
        ]);
    }

    /**
     * @param  array<string, mixed>  $change
     * @return array<string, mixed>
     */
    private function pushColorLabel(User $user, array $change): array
    {
        $id = (string) $change['id'];
        $data = (array) $change['data'];
        if (! ctype_digit($id) || (int) $id > 255 || ! is_string($data['label'] ?? null) || mb_strlen($data['label']) > 50) {
            return $this->rejected($id, 'VALIDATION_FAILED');
        }
        $color = (int) $id;

        return DB::transaction(function () use ($user, $id, $color, $data, $change): array {
            /** @var ColorLabel|null $label */
            $label = ColorLabel::query()->where('user_id', $user->id)->where('color', $color)->lockForUpdate()->first();
            $current = $label === null ? 0 : $label->version;
            if ($current !== (int) $change['base_version']) {
                return ['id' => $id, 'status' => 'conflict', 'server' => $this->labelChange($label, $id)];
            }
            $label ??= new ColorLabel(['user_id' => $user->id, 'color' => $color, 'version' => 0]);
            $label->label = $data['label'];
            $label->version = $current + 1;
            $label->save();
            $this->feed->append([$user->id], 'color_label', $id);

            return ['id' => $id, 'status' => 'applied', 'version' => $label->version];
        });
    }

    /**
     * Changes after [cursor] in the user's feed; each entity appears once
     * with its latest state.
     *
     * @return array{changes: list<array<string, mixed>>, next_cursor: int, has_more: bool}
     */
    public function pull(User $user, int $cursor, int $limit): array
    {
        $rows = DB::table('change_log')
            ->where('user_id', $user->id)
            ->where('seq', '>', $cursor)
            ->orderBy('seq')
            ->limit($limit + 1)
            ->get(['seq', 'entity', 'entity_id']);

        $hasMore = $rows->count() > $limit;
        $rows = $rows->take($limit);
        $nextCursor = (int) ($rows->last()->seq ?? $cursor);

        // Latest occurrence wins; keep feed order of last appearance.
        $latest = [];
        foreach ($rows as $row) {
            $key = $row->entity.':'.$row->entity_id;
            unset($latest[$key]);
            $latest[$key] = $row;
        }

        $noteIds = [];
        $labelIds = [];
        foreach ($latest as $row) {
            if ($row->entity === 'note') {
                $noteIds[] = $row->entity_id;
            } elseif ($row->entity === 'color_label') {
                $labelIds[] = (int) $row->entity_id;
            }
        }

        $members = NoteMember::query()
            ->with('note')
            ->where('user_id', $user->id)
            ->whereIn('note_id', $noteIds)
            ->get()
            ->keyBy('note_id');
        $labels = ColorLabel::query()
            ->where('user_id', $user->id)
            ->whereIn('color', $labelIds)
            ->get()
            ->keyBy('color');

        $changes = [];
        foreach ($latest as $row) {
            if ($row->entity === 'note') {
                /** @var NoteMember|null $member */
                $member = $members->get($row->entity_id);
                if ($member !== null && $member->note !== null) {
                    $changes[] = NotePresenter::change($member->note, $member);
                }
            } elseif ($row->entity === 'color_label') {
                $changes[] = $this->labelChange($labels->get((int) $row->entity_id), $row->entity_id);
            }
        }

        return ['changes' => $changes, 'next_cursor' => $nextCursor, 'has_more' => $hasMore];
    }

    /** @return array<string, mixed> */
    private function labelChange(?ColorLabel $label, string $id): array
    {
        return [
            'entity' => 'color_label',
            'id' => $id,
            'version' => $label === null ? 0 : $label->version,
            'data' => ['label' => $label === null ? '' : $label->label],
        ];
    }

    /**
     * @param  array<string, mixed>  $fields
     * @return array<string, mixed>
     */
    private function rejected(string $id, string $code, array $fields = []): array
    {
        $result = ['id' => $id, 'status' => 'rejected', 'error' => ['code' => $code]];
        if ($fields !== []) {
            $result['error']['fields'] = $fields;
        }

        return $result;
    }
}
