<?php

declare(strict_types=1);

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

final class KeysRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            // Opaque to the server: the wrapped master key (docs/03 §3.4).
            'key_material' => ['required', 'array'],
            'key_material.keyId' => ['required', 'string', 'max:64'],
            'key_material.wrappedDek' => ['required', 'string', 'max:512'],
            'expected_key_version' => ['required', 'integer', 'min:0'],
        ];
    }
}
