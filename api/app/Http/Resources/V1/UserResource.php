<?php

declare(strict_types=1);

namespace App\Http\Resources\V1;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin User */
final class UserResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'uuid' => $this->uuid,
            'name' => $this->name,
            'email' => $this->email,
            'has_password' => $this->password !== null,
            'google_linked' => $this->google_id !== null,
            'has_master_key' => $this->key_material !== null,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
