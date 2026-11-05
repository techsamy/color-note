<?php

declare(strict_types=1);

namespace App\Http\Requests\V1;

final class GoogleLoginRequest extends DeviceRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return ['id_token' => ['required', 'string', 'max:4096'], ...$this->deviceRules()];
    }
}
