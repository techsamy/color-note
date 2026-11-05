<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property int $user_id
 * @property string $device_uuid
 * @property string|null $name
 * @property string|null $platform
 * @property string|null $app_version
 * @property Carbon|null $last_seen_at
 */
class Device extends Model
{
    /** @var list<string> */
    protected $fillable = ['user_id', 'device_uuid', 'name', 'platform', 'app_version', 'last_seen_at'];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['last_seen_at' => 'datetime'];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
