<?php

namespace Tests\Feature\Autom8;

use App\Models\GeneratedBuild;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

class BuildDownloadTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_downloads_an_existing_build_zip(): void
    {
        $zipPath = storage_path('app/autom8/artifacts/test-build.zip');

        File::ensureDirectoryExists(dirname($zipPath));
        File::put($zipPath, 'fake zip content');

        $build = GeneratedBuild::create([
            'uuid' => '11111111-2222-3333-4444-555555555555',
            'target_distro' => 'fedora',
            'selected_profiles_json' => [],
            'selected_packages_json' => [],
            'selected_actions_json' => [],
            'manifest_json' => [],
            'zip_path' => $zipPath,
            'hash_sha256' => hash_file('sha256', $zipPath),
        ]);

        $response = $this->get(route('autom8.builds.download', $build));

        $response->assertOk();
    }
}
