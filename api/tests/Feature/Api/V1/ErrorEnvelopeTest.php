<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

it('returns the error envelope for unknown endpoints, even without an Accept header', function (): void {
    $this->get('/api/v1/does-not-exist')
        ->assertNotFound()
        ->assertExactJson(['error' => ['code' => 'NOT_FOUND', 'message' => 'Resource not found.']]);
});

it('returns 401 envelope for protected routes without a token', function (): void {
    Route::middleware(['api', 'auth:sanctum'])->get('/api/v1/_protected', fn () => 'secret');

    $this->getJson('/api/v1/_protected')
        ->assertUnauthorized()
        ->assertJsonPath('error.code', 'UNAUTHENTICATED');
});

it('returns 405 envelope for wrong method', function (): void {
    $this->postJson('/api/v1/health')
        ->assertStatus(405)
        ->assertJsonPath('error.code', 'METHOD_NOT_ALLOWED');
});
