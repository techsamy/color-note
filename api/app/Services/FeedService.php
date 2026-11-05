<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Appends entries to users' change feeds (docs/04 §3 "Feed assignment").
 * Must run inside the caller's DB transaction.
 */
final class FeedService
{
    /**
     * @param  list<int>  $userIds
     */
    public function append(array $userIds, string $entity, string $entityId): void
    {
        $userIds = array_values(array_unique($userIds));
        sort($userIds); // fixed lock order avoids deadlocks

        /** @var Collection<int, User> $users */
        $users = User::query()->whereKey($userIds)->orderBy('id')->lockForUpdate()->get(['id', 'feed_seq']);

        $rows = [];
        foreach ($users as $user) {
            $seq = $user->feed_seq + 1;
            User::query()->whereKey($user->id)->update(['feed_seq' => $seq]);
            $rows[] = [
                'user_id' => $user->id,
                'seq' => $seq,
                'entity' => $entity,
                'entity_id' => $entityId,
                'created_at' => now(),
            ];
        }
        DB::table('change_log')->insert($rows);
    }
}
