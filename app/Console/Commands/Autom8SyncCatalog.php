<?php

namespace App\Console\Commands;

use App\Services\Autom8\Catalog\CatalogReader;
use App\Services\Autom8\Catalog\CatalogSyncService;
use App\Services\Autom8\Catalog\CatalogValidator;
use Illuminate\Console\Command;
use Throwable;

class Autom8SyncCatalog extends Command
{
    protected $signature = 'autom8:sync-catalog {--publish-version=}';

    protected $description = 'Read, validate and synchronize the AutoM8 catalog from YAML files';

    public function handle(
        CatalogReader $reader,
        CatalogValidator $validator,
        CatalogSyncService $syncService
    ): int {
        try {
            $this->info('Reading catalog files...');
            $catalog = $reader->readAll();

            $this->info('Validating catalog structure...');
            $validator->validate($catalog);

            $version = $this->option('publish-version');

            $this->info('Synchronizing catalog to database...');
            $result = $syncService->sync($catalog, $version);

            $this->newLine();
            $this->info('AutoM8 catalog synchronized successfully.');
            $this->line('Distros: ' . $result['distros']);
            $this->line('Packages: ' . $result['packages']);
            $this->line('Profiles: ' . $result['profiles']);
            $this->line('System actions: ' . $result['system_actions']);

            if (! empty($result['catalog_version'])) {
                $this->line('Catalog version: ' . $result['catalog_version']);
            }

            return self::SUCCESS;
        } catch (Throwable $e) {
            $this->newLine();
            $this->error('Catalog synchronization failed.');
            $this->error($e->getMessage());

            return self::FAILURE;
        }
    }
}
