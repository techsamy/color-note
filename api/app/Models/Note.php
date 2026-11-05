<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Shared content of a note. Per-user state lives in NoteMember.
 *
 * @property string $id
 * @property int $owner_id
 * @property int $type
 * @property string $title
 * @property string $body
 * @property bool $is_locked
 * @property array<string, mixed>|null $crypto_meta
 * @property string|null $calendar_date
 * @property int $client_created_at
 * @property int $client_updated_at
 * @property int|null $deleted_at
 * @property bool $purged
 * @property int $version
 * @property int|null $updated_by_device_id
 */
class Note extends Model
{
    public $incrementing = false;

    protected $keyType = 'string';

    /** @var list<string> */
    protected $guarded = [];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'is_locked' => 'boolean',
            'purged' => 'boolean',
            'crypto_meta' => 'array',
            'type' => 'integer',
            'version' => 'integer',
            'client_created_at' => 'integer',
            'client_updated_at' => 'integer',
            'deleted_at' => 'integer',
        ];
    }

    /** @return HasMany<NoteMember, $this> */
    public function members(): HasMany
    {
        return $this->hasMany(NoteMember::class);
    }
}
