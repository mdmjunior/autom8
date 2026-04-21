<?php

use App\DTO\BuildSelectionData;
use App\Models\Distro;
use App\Models\Package;
use App\Models\PackageVariant;
use App\Models\Profile;
use App\Models\SystemAction;
use App\Services\Autom8\Build\SelectionResolver;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

uses(TestCase::class, RefreshDatabase::class);

it('resolves profiles manual packages and actions', function () {
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

    $vlc = Package::query()->create([
        'name' => 'VLC',
        'slug' => 'vlc',
        'category' => 'media',
        'install_method' => validPackageInstallMethod(),
        'description' => 'VLC package',
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

    PackageVariant::query()->create([
        'package_id' => $vlc->id,
        'distro_id' => $distro->id,
        'package_name' => 'vlc',
        'install_method' => validPackageInstallMethod(),
        'install_command' => 'dnf install -y vlc',
        'remove_command' => 'dnf remove -y vlc',
    ]);

    $profile = Profile::query()->create([
        'name' => 'Developer',
        'slug' => 'developer',
        'description' => 'Developer profile',
        'is_active' => true,
    ]);

    $profile->packages()->attach([$git->id]);

    SystemAction::query()->create([
        'name' => 'System Update',
        'slug' => 'system-update',
        'description' => 'Run system update',
        'script_template' => 'echo update',
        'input_schema_json' => null,
        'is_active' => true,
    ]);

    $selection = BuildSelectionData::fromArray([
        'distro_slug' => 'fedora',
        'selected_profile_slugs' => ['developer'],
        'selected_package_slugs' => ['vlc'],
        'selected_action_slugs' => ['system-update'],
        'action_inputs' => [],
    ]);

    $resolved = app(SelectionResolver::class)->resolve($selection);

    expect(collect($resolved['profiles'])->pluck('slug')->all())->toBe(['developer']);
    expect(collect($resolved['packages'])->pluck('slug')->sort()->values()->all())->toBe(['git', 'vlc']);
    expect(collect($resolved['actions'])->pluck('slug')->all())->toBe(['system-update']);
});
