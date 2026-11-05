<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * 426 APP_UPGRADE_REQUIRED for apps older than huenote.min_supported_version.
 * Requests without the header (curl, tests, web tools) are let through.
 */
final class EnsureSupportedAppVersion
{
    public function handle(Request $request, Closure $next): Response
    {
        $header = (string) $request->header('X-App-Version', '');
        if ($header !== '') {
            $version = explode('+', $header)[0];
            if (version_compare($version, (string) config('huenote.min_supported_version'), '<')) {
                abort(426, 'Please update the app to continue.');
            }
        }

        return $next($request);
    }
}
