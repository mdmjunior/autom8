<?php

namespace Tests\Feature\Autom8;

use App\DTO\BuildSelectionData;
use App\Models\CatalogVersion;
use App\Models\Distro;
use App\Models\Package;
use App\Models\PackageVariant;
use App\Models\SystemAction;
use App\Services\Autom8\Build\BuildGeneratorService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BuildGeneratorServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_generates_a_build_record(): void
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
            'description' => 'Git package',
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

        CatalogVersion::create([
            'version' => '0.1.0',
            'notes' => 'test version',
            'published_at' => now(),
        ]);

        $selection = BuildSelectionData::fromArray([
            'distro_slug' => 'fedora',
            'selected_package_slugs' => ['git'],
            'selected_action_slugs' => ['system-update'],
        ]);

        $build = app(BuildGeneratorService::class)->generate($selection);

        $this->assertDatabaseHas('generated_builds', [
            'id' => $build->id,
            'uuid' => $build->uuid,
            'target_distro' => 'fedora',
        ]);

        $this->assertFileExists($build->zip_path);
        $this->assertNotEmpty($build->hash_sha256);
    }
}
