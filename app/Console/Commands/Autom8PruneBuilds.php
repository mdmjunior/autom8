<?php

namespace App\Console\Commands;

use App\Models\GeneratedBuild;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;

class Autom8PruneBuilds extends Command
{
    protected $signature = 'autom8:prune-builds {--days=30} {--dry-run}';

    protected $description = 'Remove old AutoM8 builds, ZIP artifacts and orphaned directories/files';

    public function handle(): int
    {
        $days = (int) $this->option('days');
        $dryRun = (bool) $this->option('dry-run');
        $cutoff = now()->subDays($days);

        $this->info("Pruning AutoM8 builds older than {$days} day(s)...");
        if ($dryRun) {
            $this->warn('Dry-run mode enabled. No files will be deleted.');
        }

        $deletedBuildRows = 0;
        $deletedZipFiles = 0;
        $deletedBuildDirs = 0;
        $deletedOrphanZipFiles = 0;
        $deletedOrphanBuildDirs = 0;

        $oldBuilds = GeneratedBuild::query()
            ->where('created_at', '<', $cutoff)
            ->get();

        foreach ($oldBuilds as $build) {
            $zipPath = $build->zip_path;
            $buildDir = storage_path('app/autom8/builds/' . $build->uuid);

            $this->line("Old build: {$build->uuid}");

            if ($zipPath && File::exists($zipPath)) {
                $this->line(" - ZIP: {$zipPath}");
                if (! $dryRun) {
                    File::delete($zipPath);
                    $deletedZipFiles++;
                }
            }

            if (File::isDirectory($buildDir)) {
                $this->line(" - Build dir: {$buildDir}");
                if (! $dryRun) {
                    File::deleteDirectory($buildDir);
                    $deletedBuildDirs++;
                }
            }

            if (! $dryRun) {
                $build->delete();
                $deletedBuildRows++;
            }
        }

        [$orphanZipFiles, $orphanBuildDirs] = $this->findOrphans();

        foreach ($orphanZipFiles as $zipPath) {
            $this->line("Orphan ZIP: {$zipPath}");
            if (! $dryRun) {
                File::delete($zipPath);
                $deletedOrphanZipFiles++;
            }
        }

        foreach ($orphanBuildDirs as $buildDir) {
            $this->line("Orphan build dir: {$buildDir}");
            if (! $dryRun) {
                File::deleteDirectory($buildDir);
                $deletedOrphanBuildDirs++;
            }
        }

        Log::info('AutoM8 prune builds executed.', [
            'days' => $days,
            'dry_run' => $dryRun,
            'deleted_build_rows' => $deletedBuildRows,
            'deleted_zip_files' => $deletedZipFiles,
            'deleted_build_dirs' => $deletedBuildDirs,
            'deleted_orphan_zip_files' => $deletedOrphanZipFiles,
            'deleted_orphan_build_dirs' => $deletedOrphanBuildDirs,
        ]);

        $this->newLine();
        $this->info('AutoM8 prune finished.');
        $this->line("Deleted DB rows: {$deletedBuildRows}");
        $this->line("Deleted ZIP files: {$deletedZipFiles}");
        $this->line("Deleted build dirs: {$deletedBuildDirs}");
        $this->line("Deleted orphan ZIP files: {$deletedOrphanZipFiles}");
        $this->line("Deleted orphan build dirs: {$deletedOrphanBuildDirs}");

        return self::SUCCESS;
    }

    protected function findOrphans(): array
    {
        $knownBuilds = GeneratedBuild::query()
            ->get(['uuid', 'zip_path'])
            ->map(fn($build) => [
                'uuid' => $build->uuid,
                'zip_path' => $build->zip_path,
            ]);

        $knownZipPaths = $knownBuilds->pluck('zip_path')->filter()->values()->all();
        $knownUuids = $knownBuilds->pluck('uuid')->filter()->values()->all();

        $artifactDir = storage_path('app/autom8/artifacts');
        $buildsDir = storage_path('app/autom8/builds');

        $orphanZipFiles = [];
        $orphanBuildDirs = [];

        if (File::isDirectory($artifactDir)) {
            foreach (File::files($artifactDir) as $file) {
                $path = $file->getRealPath();

                if ($path && ! in_array($path, $knownZipPaths, true)) {
                    $orphanZipFiles[] = $path;
                }
            }
        }

        if (File::isDirectory($buildsDir)) {
            foreach (File::directories($buildsDir) as $dir) {
                $uuid = basename($dir);

                if (! in_array($uuid, $knownUuids, true)) {
                    $orphanBuildDirs[] = $dir;
                }
            }
        }

        return [$orphanZipFiles, $orphanBuildDirs];
    }
}
