<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Device;
use App\Models\User;

final class AuthService
{
    /**
     * Issues a Sanctum token for one device. Token name = device uuid so a
     * device can be revoked later (DELETE /devices/{uuid}).
     *
     * @return array{token: string, device: Device}
     */
    public function issueToken(User $user, string $deviceUuid, ?string $deviceName, ?string $platform, ?string $appVersion): array
    {
        // One live token per device: signing in again replaces the old one.
        $user->tokens()->where('name', $deviceUuid)->delete();
        $token = $user->createToken($deviceUuid)->plainTextToken;

        $device = Device::query()->updateOrCreate(
            ['user_id' => $user->id, 'device_uuid' => $deviceUuid],
            [
                'name' => $deviceName,
                'platform' => $platform,
                'app_version' => $appVersion,
                'last_seen_at' => now(),
            ],
        );

        return ['token' => $token, 'device' => $device];
    }
}
