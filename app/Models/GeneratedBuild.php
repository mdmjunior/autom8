<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GeneratedBuild extends Model
{
    protected $fillable = [
        'uuid',
        'target_distro',
        'selected_profiles_json',
        'selected_packages_json',
        'selected_actions_json',
        'manifest_json',
        'zip_path',
        'hash_sha256',
    ];

    protected $casts = [
        'selected_profiles_json' => 'array',
        'selected_packages_json' => 'array',
        'selected_actions_json' => 'array',
        'manifest_json' => 'array',
    ];
}
