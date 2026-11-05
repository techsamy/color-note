<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property string $note_id
 * @property int $user_id
 * @property int $permission
 * @property int $status
 * @property int $color
 * @property bool $is_pinned
 * @property bool $is_archived
 * @property int|null $reminder_at
 * @property array<string, mixed>|null $reminder_rule
 * @property bool $reminder_all_day
 * @property bool $status_bar_pinned
 */
class NoteMember extends Model
{
    public const PERMISSION_OWNER = 0;

    public const PERMISSION_EDITOR = 1;

    public const PERMISSION_VIEWER = 2;

    public const STATUS_PENDING = 0;

    public const STATUS_ACTIVE = 1;

    public const STATUS_REMOVED = 2;

    /** @var list<string> */
    protected $guarded = [];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'permission' => 'integer',
            'status' => 'integer',
            'color' => 'integer',
            'is_pinned' => 'boolean',
            'is_archived' => 'boolean',
            'reminder_at' => 'integer',
            'reminder_rule' => 'array',
            'reminder_all_day' => 'boolean',
            'status_bar_pinned' => 'boolean',
        ];
    }

    /** @return BelongsTo<Note, $this> */
    public function note(): BelongsTo
    {
        return $this->belongsTo(Note::class);
    }
}
