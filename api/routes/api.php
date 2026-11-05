<?php

declare(strict_types=1);

use App\Http\Controllers\Api\V1\AccountController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\ConfigController;
use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Middleware\EnsureSupportedAppVersion;
use App\Http\Middleware\TrackDevice;
use Illuminate\Support\Facades\Route;

/*
| All endpoints live under /api/v1. Additive changes only; breaking changes go to /api/v2.
| Contract: docs/05-api-spec.md.
*/
Route::prefix('v1')->name('v1.')->group(function (): void {
    Route::get('/health', HealthController::class)->name('health');
    Route::get('/config', ConfigController::class)->name('config');

    Route::middleware([EnsureSupportedAppVersion::class])->group(function (): void {
        Route::middleware('throttle:auth')->prefix('auth')->name('auth.')->group(function (): void {
            Route::post('/register', [AuthController::class, 'register'])->name('register');
            Route::post('/login', [AuthController::class, 'login'])->name('login');
            Route::post('/google', [AuthController::class, 'google'])->name('google');
            Route::post('/password/forgot', [AuthController::class, 'forgotPassword'])->name('password.forgot');
            Route::post('/password/reset', [AuthController::class, 'resetPassword'])->name('password.reset');
        });

        Route::middleware(['auth:sanctum', TrackDevice::class])->group(function (): void {
            Route::post('/auth/logout', [AuthController::class, 'logout'])->name('auth.logout');

            Route::get('/me', [AccountController::class, 'show'])->name('me');
            Route::patch('/me', [AccountController::class, 'update'])->name('me.update');
            Route::put('/me/password', [AccountController::class, 'changePassword'])->name('me.password');
            Route::delete('/me', [AccountController::class, 'destroy'])->name('me.destroy');
            Route::get('/me/keys', [AccountController::class, 'keys'])->name('me.keys');
            Route::put('/me/keys', [AccountController::class, 'updateKeys'])->name('me.keys.update');
            Route::delete('/devices/{deviceUuid}', [AccountController::class, 'destroyDevice'])->name('devices.destroy');

            Route::middleware('throttle:sync')->group(function (): void {
                Route::post('/sync/push', [SyncController::class, 'push'])->name('sync.push');
                Route::get('/sync/pull', [SyncController::class, 'pull'])->name('sync.pull');
            });
        });
    });
});
