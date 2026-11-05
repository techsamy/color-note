<?php

declare(strict_types=1);

namespace App\Providers;

use App\Contracts\GoogleIdTokenVerifier;
use App\Services\HttpGoogleIdTokenVerifier;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(GoogleIdTokenVerifier::class, function (): GoogleIdTokenVerifier {
            /** @var list<string> $ids */
            $ids = config('services.google.client_ids', []);

            return new HttpGoogleIdTokenVerifier($ids);
        });
    }

    public function boot(): void
    {
        // docs/05 §1: auth 10/min/IP, sync 60/min/user.
        RateLimiter::for('auth', fn (Request $request) => Limit::perMinute(10)->by((string) $request->ip()));
        RateLimiter::for('sync', fn (Request $request) => Limit::perMinute(60)->by((string) ($request->user()?->getAuthIdentifier() ?? $request->ip())));

        // Reset links open the app (deep link) / web page — not a Laravel view.
        ResetPassword::createUrlUsing(fn (object $user, string $token): string => rtrim((string) config('app.frontend_url', config('app.url')), '/')
            .'/reset-password?token='.urlencode($token).'&email='.urlencode((string) ($user->email ?? '')));
    }
}
