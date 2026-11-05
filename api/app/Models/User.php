<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

/**
 * @property int $id
 * @property string $uuid
 * @property string|null $name
 * @property string $email
 * @property string|null $password
 * @property string|null $google_id
 * @property int $feed_seq
 * @property array<string, mixed>|null $key_material
 * @property int $key_version
 */
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /** @var list<string> */
    protected $fillable = ['name', 'email', 'password', 'google_id'];

    /** @var list<string> */
    protected $hidden = ['password', 'remember_token', 'key_material'];

    protected static function booted(): void
    {
        static::creating(function (User $user): void {
            $user->uuid ??= (string) Str::uuid();
        });
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'key_material' => 'array',
            'feed_seq' => 'integer',
            'key_version' => 'integer',
        ];
    }

    /** @return HasMany<Device, $this> */
    public function devices(): HasMany
    {
        return $this->hasMany(Device::class);
    }

    /** @return HasMany<NoteMember, $this> */
    public function memberships(): HasMany
    {
        return $this->hasMany(NoteMember::class);
    }

    /** @return HasMany<ColorLabel, $this> */
    public function colorLabels(): HasMany
    {
        return $this->hasMany(ColorLabel::class);
    }
}
