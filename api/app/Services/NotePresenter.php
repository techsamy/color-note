<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Note;
use App\Models\NoteMember;

/**
 * Server split (notes + note_members) -> the single flat note object the
 * app works with (docs/05 §4).
 */
final class NotePresenter
{
    /** @return array<string, mixed> */
    public static function data(Note $note, NoteMember $member): array
    {
        return [
            'type' => $note->type,
            'title' => $note->title,
            'body' => $note->body,
            'is_locked' => $note->is_locked,
            'crypto_meta' => $note->crypto_meta,
            'calendar_date' => $note->calendar_date,
            'created_at' => $note->client_created_at,
            'updated_at' => $note->client_updated_at,
            'deleted_at' => $note->deleted_at,
            'purged' => $note->purged,
            'color' => $member->color,
            'is_pinned' => $member->is_pinned,
            'is_archived' => $member->is_archived,
            'reminder_at' => $member->reminder_at,
            'reminder_rule' => $member->reminder_rule,
            'reminder_all_day' => $member->reminder_all_day,
            'status_bar_pinned' => $member->status_bar_pinned,
        ];
    }

    /** @return array<string, mixed> */
    public static function change(Note $note, NoteMember $member): array
    {
        return [
            'entity' => 'note',
            'id' => $note->id,
            'version' => $note->version,
            'my_permission' => $member->permission,
            'data' => self::data($note, $member),
        ];
    }
}
