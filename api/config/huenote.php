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

    // Public website (privacy policy, terms, support, account deletion, password reset).
    'site' => [
        'support_email' => env('HUENOTE_SUPPORT_EMAIL', 'vivekary@gmail.com'),
        // Shown on the legal pages as the developer. Empty = not shown.
        'publisher' => env('HUENOTE_PUBLISHER', ''),
        'country' => env('HUENOTE_COUNTRY', 'India'),
        // Set once the app is live on Google Play; until then the site says "Coming soon".
        'play_store_url' => env('HUENOTE_PLAY_STORE_URL', ''),
        // Bump when the privacy policy or terms change.
        'legal_updated' => '6 November 2026',
    ],
];
