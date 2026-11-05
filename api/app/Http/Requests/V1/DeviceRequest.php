<?php

declare(strict_types=1);

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

/** Shared device fields for every sign-in request. */
abstract class DeviceRequest extends FormRequest
{
    /** @return array<string, mixed> */
    protected function deviceRules(): array
    {
        return [
            'device_uuid' => ['required', 'uuid'],
            'device_name' => ['nullable', 'string', 'max:100'],
            'platform' => ['nullable', 'string', 'max:20'],
        ];
    }
}
