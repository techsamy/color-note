<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\V1\SyncPushRequest;
use App\Models\Device;
use App\Models\User;
use App\Services\SyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

final class SyncController extends Controller
{
    public function __construct(private readonly SyncService $sync) {}

    public function push(SyncPushRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();
        $device = $request->attributes->get('device');

        /** @var list<array<string, mixed>> $changes */
        $changes = $request->validated('changes');

        return response()->json(['data' => [
            'results' => $this->sync->push($user, $device instanceof Device ? $device : null, $changes),
        ]]);
    }

    public function pull(Request $request): JsonResponse
    {
        $request->validate([
            'cursor' => ['nullable', 'integer', 'min:0'],
            'limit' => ['nullable', 'integer', 'min:1', 'max:500'],
        ]);
        /** @var User $user */
        $user = $request->user();
        $page = $this->sync->pull($user, $request->integer('cursor'), $request->integer('limit', 500));

        return response()->json([
            'data' => ['changes' => $page['changes']],
            'meta' => [
                'next_cursor' => $page['next_cursor'],
                'has_more' => $page['has_more'],
                'server_time' => now()->getTimestampMs(),
            ],
        ]);
    }
}
