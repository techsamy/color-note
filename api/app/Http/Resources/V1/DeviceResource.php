<?php

declare(strict_types=1);

namespace App\Http\Resources\V1;

use App\Models\Device;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Device */
final class DeviceResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'device_uuid' => $this->device_uuid,
            'name' => $this->name,
            'platform' => $this->platform,
            'app_version' => $this->app_version,
            'last_seen_at' => $this->last_seen_at?->toIso8601String(),
        ];
    }
}
