<?php

declare(strict_types=1);

use App\Http\Controllers\Api\V1\ConfigController;
use App\Http\Controllers\Api\V1\HealthController;
use Illuminate\Support\Facades\Route;

/*
| All endpoints live under /api/v1. Additive changes only; breaking changes go to /api/v2.
| See docs/05-api-spec.md.
*/
Route::prefix('v1')->name('v1.')->group(function (): void {
    Route::get('/health', HealthController::class)->name('health');
    Route::get('/config', ConfigController::class)->name('config');
});
