<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SystemAction extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'description',
        'input_type',
        'input_options',
        'validation_rules',
        'script_template_ubuntu',
        'script_template_fedora',
        'is_active',
    ];

    protected $casts = [
        'input_options' => 'array',
        'is_active' => 'boolean',
    ];
}
