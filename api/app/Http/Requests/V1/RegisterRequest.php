<?php

declare(strict_types=1);

namespace App\Http\Requests\V1;

use Illuminate\Validation\Rules\Password;

final class RegisterRequest extends DeviceRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email:rfc', 'max:191', 'unique:users,email'],
            'password' => ['required', 'string', Password::min(8)],
            'name' => ['nullable', 'string', 'max:100'],
            ...$this->deviceRules(),
        ];
    }

    protected function prepareForValidation(): void
    {
        $this->merge(['email' => strtolower(trim((string) $this->input('email')))]);
    }
}
