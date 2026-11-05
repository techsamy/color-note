<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

/**
 * Public remote config: version gates and feature flags for the app.
 */
final class ConfigController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'data' => [
                'min_supported_version' => config('huenote.min_supported_version'),
                'latest_version' => config('huenote.latest_version'),
                'features' => config('huenote.features'),
            ],
        ]);
    }
}
