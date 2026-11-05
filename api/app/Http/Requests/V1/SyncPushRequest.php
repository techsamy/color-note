<?php

declare(strict_types=1);

namespace App\Http\Requests\V1;

use Illuminate\Foundation\Http\FormRequest;

/** Envelope only; each change's data is validated per record in SyncService. */
final class SyncPushRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'changes' => ['present', 'array', 'max:200'],
            'changes.*.entity' => ['required', 'string', 'max:20'],
            'changes.*.id' => ['required', 'string', 'max:40'],
            'changes.*.base_version' => ['required', 'integer', 'min:0'],
            'changes.*.data' => ['required', 'array'],
        ];
    }
}
