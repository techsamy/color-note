<?php

declare(strict_types=1);

it('reports health with server time', function (): void {
    $this->getJson('/api/v1/health')
        ->assertOk()
        ->assertJsonPath('data.status', 'ok')
        ->assertJsonStructure(['data' => ['status', 'server_time']]);
});

it('returns public app config', function (): void {
    config()->set('huenote.min_supported_version', '1.2.0');

    $this->getJson('/api/v1/config')
        ->assertOk()
        ->assertJsonPath('data.min_supported_version', '1.2.0')
        ->assertJsonStructure(['data' => ['min_supported_version', 'latest_version', 'features' => ['sync', 'calendar', 'sharing']]]);
});
