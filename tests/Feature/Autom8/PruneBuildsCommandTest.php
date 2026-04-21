<?php

namespace Tests\Feature\Autom8;

use App\Models\GeneratedBuild;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

class PruneBuildsCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_prunes_old_builds_and_files(): void
    {
        $uuid = '11111111-2222-3333-4444-555555555555';
        $zipPath = storage_path("app/autom8/artifacts/{$uuid}.zip");
        $buildDir = storage_path("app/autom8/builds/{$uuid}");

        File::ensureDirectoryExists(dirname($zipPath));
        File::ensureDirectoryExists($buildDir);

        File::put($zipPath, 'fake zip');
        File::put($buildDir . '/manifest.json', '{}');

        $build = GeneratedBuild::create([
            'uuid' => $uuid,
            'target_distro' => 'fedora',
            'selected_profiles_json' => [],
            'selected_packages_json' => [],
            'selected_actions_json' => [],
            'manifest_json' => [],
            'zip_path' => $zipPath,
            'hash_sha256' => hash_file('sha256', $zipPath),
        ]);

        $build->created_at = now()->subDays(40);
        $build->save();

        $this->artisan('autom8:prune-builds', ['--days' => 30])
            ->assertExitCode(0);

        $this->assertDatabaseMissing('generated_builds', [
            'uuid' => $uuid,
        ]);

        $this->assertFileDoesNotExist($zipPath);
        $this->assertDirectoryDoesNotExist($buildDir);
    }
}
