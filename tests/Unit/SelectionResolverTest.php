<?php

namespace Tests\Unit;

use App\DTO\BuildSelectionData;
use App\Models\Distro;
use App\Models\Package;
use App\Models\PackageVariant;
use App\Models\Profile;
use App\Models\SystemAction;
use App\Services\Autom8\Build\SelectionResolver;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SelectionResolverTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_resolves_profiles_manual_packages_and_actions(): void
    {
        $fedora = Distro::create([
            'name' => 'Fedora',
            'slug' => 'fedora',
            'is_active' => true,
        ]);

        $package = Package::create([
            'name' => 'Git',
            'slug' => 'git',
            'category' => 'Utilities',
            'install_method' => 'dnf',
            'risk_level' => 'low',
            'requires_reboot' => false,
            'requires_third_party_repo' => false,
            'is_active' => true,
            'is_featured' => true,
            'tags' => ['git'],
        ]);

        PackageVariant::create([
            'package_id' => $package->id,
            'distro_id' => $fedora->id,
            'install_command' => 'sudo dnf install -y git',
            'is_supported' => true,
        ]);

        $profile = Profile::create([
            'name' => 'Developer',
            'slug' => 'developer',
            'description' => 'Developer profile',
            'icon' => 'code-2',
            'is_active' => true,
        ]);

        $profile->packages()->attach($package->id, ['is_default' => true]);

        SystemAction::create([
            'name' => 'Atualizar sistema',
            'slug' => 'system-update',
            'description' => 'Update system',
            'input_type' => 'boolean',
            'validation_rules' => 'nullable|boolean',
            'script_template_ubuntu' => 'sudo apt update && sudo apt upgrade -y',
            'script_template_fedora' => 'sudo dnf upgrade --refresh -y',
            'is_active' => true,
        ]);

        $selection = BuildSelectionData::fromArray([
            'distro_slug' => 'fedora',
            'selected_profile_slugs' => ['developer'],
            'selected_action_slugs' => ['system-update'],
        ]);

        $result = app(SelectionResolver::class)->resolve($selection);

        $this->assertSame('fedora', $result['distro']['slug']);
        $this->assertCount(1, $result['packages']);
        $this->assertSame('git', $result['packages'][0]['slug']);
        $this->assertCount(1, $result['actions']);
        $this->assertSame('system-update', $result['actions'][0]['slug']);
    }
}
