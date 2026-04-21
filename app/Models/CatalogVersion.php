<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CatalogVersion extends Model
{
    protected $fillable = [
        'version',
        'notes',
        'published_at',
    ];

    protected $casts = [
        'published_at' => 'datetime',
    ];
}
