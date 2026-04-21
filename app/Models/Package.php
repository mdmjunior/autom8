<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Package extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'category',
        'description',
        'icon',
        'homepage_url',
        'install_method',
        'risk_level',
        'requires_reboot',
        'requires_third_party_repo',
        'is_active',
        'is_featured',
        'tags',
    ];

    protected $casts = [
        'tags' => 'array',
        'requires_reboot' => 'boolean',
        'requires_third_party_repo' => 'boolean',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
    ];

    public function variants(): HasMany
    {
        return $this->hasMany(PackageVariant::class);
    }

    public function profiles(): BelongsToMany
    {
        return $this->belongsToMany(Profile::class, 'profile_package')
            ->withPivot('is_default')
            ->withTimestamps();
    }
}
