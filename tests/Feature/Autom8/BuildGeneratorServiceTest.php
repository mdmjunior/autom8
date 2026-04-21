<?php

use App\DTO\BuildSelectionData;
use App\Models\CatalogVersion;
use App\Models\Distro;
use App\Models\Package;
use App\Models\PackageVariant;
use App\Models\Profile;
use App\Models\SystemAction;
use App\Services\Autom8\Build\BuildGeneratorService;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

it('generates a build record', function () {
    $distro = Distro::query()->create([
        'name' => 'Fedora',
        'slug' => 'fedora',
        'is_active' => true,
    ]);

    $git = Package::query()->create([
        'name' => 'Git',
        'slug' => 'git',
        'category' => 'development',
        'install_method' => validPackageInstallMethod(),
        'description' => 'Git package',
        'is_active' => true,
    ]);

    PackageVariant::query()->create([
        'package_id' => $git->id,
        'distro_id' => $distro->id,
        'package_name' => 'git',
        'install_method' => validPackageInstallMethod(),
        'install_command' => 'dnf install -y git',
        'remove_command' => 'dnf remove -y git',
    ]);

    $profile = Profile::query()->create([
        'name' => 'Developer',
        'slug' => 'developer',
        'description' => 'Developer profile',
        'is_active' => true,
    ]);

    $profile->packages()->attach([$git->id]);

    SystemAction::query()->create([
        'name' => 'Set Hostname',
        'slug' => 'set-hostname',
        'description' => 'Set system hostname',
        'script_template' => 'hostnamectl set-hostname "{{ value }}"',
        'input_schema_json' => [
            'type' => 'string',
            'required' => true,
        ],
        'is_active' => true,
    ]);

    CatalogVersion::query()->create([
        'version' => '0.1.0',
        'published_at' => now(),
        'catalog_snapshot_json' => [],
    ]);

    $selection = BuildSelectionData::fromArray([
        'distro_slug' => 'fedora',
        'selected_profile_slugs' => ['developer'],
        'selected_package_slugs' => [],
        'selected_action_slugs' => ['set-hostname'],
        'action_inputs' => [
            'set-hostname' => 'autom8-devbox',
        ],
    ]);

    $build = app(BuildGeneratorService::class)->generate($selection);

    expect($build->exists)->toBeTrue();
    expect($build->target_distro)->toBe('fedora');
    expect($build->uuid)->not->toBeEmpty();
    expect($build->zip_path)->not->toBeEmpty();
    expect($build->hash_sha256)->not->toBeEmpty();
    expect($build->manifest_json)->toBeArray();
});
