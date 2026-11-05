<?php

declare(strict_types=1);

return [
    // Apps below this version receive 426 APP_UPGRADE_REQUIRED (enforced from v1.0).
    'min_supported_version' => env('HUENOTE_MIN_APP_VERSION', '0.1.0'),
    'latest_version' => env('HUENOTE_LATEST_APP_VERSION', '0.1.0'),

    // Remote feature flags; the app keeps local defaults when offline.
    'features' => [
        'sync' => (bool) env('HUENOTE_FEATURE_SYNC', false),
        'calendar' => (bool) env('HUENOTE_FEATURE_CALENDAR', false),
        'sharing' => (bool) env('HUENOTE_FEATURE_SHARING', false),
    ],
];
