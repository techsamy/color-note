<?php

declare(strict_types=1);

use App\Http\Controllers\Web\DeleteAccountController;
use App\Http\Controllers\Web\ResetPasswordController;
use App\Http\Controllers\Web\SiteController;
use Illuminate\Support\Facades\Route;

// Public website — docs/09-roadmap.md "Small website".
Route::get('/', [SiteController::class, 'home'])->name('site.home');
Route::get('/privacy', [SiteController::class, 'privacy'])->name('site.privacy');
Route::get('/terms', [SiteController::class, 'terms'])->name('site.terms');
Route::get('/support', [SiteController::class, 'support'])->name('site.support');

// Play policy: account deletion must be possible without the app (FR-B6).
Route::get('/delete-account', [DeleteAccountController::class, 'show'])->name('site.delete-account');
Route::post('/delete-account', [DeleteAccountController::class, 'destroy'])
    ->middleware('throttle:auth')->name('site.delete-account.submit');

// Target of the password-reset email (AppServiceProvider::boot).
Route::get('/reset-password', [ResetPasswordController::class, 'show'])->name('site.reset-password');
Route::post('/reset-password', [ResetPasswordController::class, 'update'])
    ->middleware('throttle:auth')->name('site.reset-password.submit');
