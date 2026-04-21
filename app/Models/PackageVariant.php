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
        'repository_setup_command',
        'pre_install_command',
        'install_command',
        'post_install_command',
        'remove_command',
        'is_supported',
    ];

    protected $casts = [
        'is_supported' => 'boolean',
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
