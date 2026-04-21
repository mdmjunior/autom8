<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PackageVariant extends Model
{
    protected $fillable = [
        'package_id',
        'distro_id',
        'package_name',
        'install_method',
        'install_command',
        'remove_command',
        'notes',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function package(): BelongsTo
    {
        return $this->belongsTo(Package::class);
    }

    public function distro(): BelongsTo
    {
        return $this->belongsTo(Distro::class);
    }
}
