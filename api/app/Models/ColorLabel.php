<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * @property int $id
 * @property int $user_id
 * @property int $color
 * @property string $label
 * @property int $version
 */
class ColorLabel extends Model
{
    /** @var list<string> */
    protected $fillable = ['user_id', 'color', 'label', 'version'];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['color' => 'integer', 'version' => 'integer'];
    }
}
