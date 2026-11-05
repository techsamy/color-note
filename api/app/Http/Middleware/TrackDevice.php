<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Models\Device;
use App\Models\User;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

/**
 * Resolves the calling device from X-Device-Id (+ X-App-Version) and keeps
 * last_seen_at fresh. Available later as $request->attributes->get('device').
 */
final class TrackDevice
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $uuid = (string) $request->header('X-Device-Id', '');
        if ($user instanceof User && Str::isUuid($uuid)) {
            $device = Device::query()->firstOrNew(['user_id' => $user->id, 'device_uuid' => $uuid]);
            $device->app_version = $request->header('X-App-Version', $device->app_version);
            if ($device->last_seen_at === null || $device->last_seen_at->lt(now()->subMinute())) {
                $device->last_seen_at = now();
            }
            if ($device->isDirty()) {
                $device->save();
            }
            $request->attributes->set('device', $device);
        }

        return $next($request);
    }
}
