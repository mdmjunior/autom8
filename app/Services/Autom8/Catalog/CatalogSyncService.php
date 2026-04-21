<?php

namespace App\Services\Autom8\Catalog;

use App\Models\CatalogVersion;
use App\Models\Distro;
use App\Models\Package;
use App\Models\PackageVariant;
use App\Models\Profile;
use App\Models\SystemAction;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class CatalogSyncService
{
    public function sync(array $catalog, ?string $version = null): array
    {
        return DB::transaction(function () use ($catalog, $version) {
            $distroMap = $this->syncDistros($catalog['distros'] ?? []);
            $packageMap = $this->syncPackages($catalog['packages'] ?? [], $distroMap);
            $profileMap = $this->syncProfiles($catalog['profiles'] ?? []);
            $this->syncProfilePackages($catalog['profiles'] ?? [], $packageMap, $profileMap);
            $systemActionsCount = $this->syncSystemActions($catalog['system_actions'] ?? []);
            $catalogVersion = $this->syncCatalogVersion($version);

            return [
                'distros' => count($distroMap),
                'packages' => count($packageMap),
                'profiles' => count($profileMap),
                'system_actions' => $systemActionsCount,
                'catalog_version' => $catalogVersion?->version,
            ];
        });
    }

    protected function syncDistros(array $distros): array
    {
        $map = [];

        foreach ($distros as $distro) {
            $model = Distro::updateOrCreate(
                ['slug' => $distro['slug']],
                [
                    'name' => $distro['name'],
                    'is_active' => (bool) $distro['is_active'],
                ]
            );

            $map[$distro['slug']] = $model;
        }

        return $map;
    }

    protected function syncPackages(array $packages, array $distroMap): array
    {
        $map = [];

        foreach ($packages as $package) {
            $model = Package::updateOrCreate(
                ['slug' => $package['slug']],
                [
                    'name' => $package['name'],
                    'category' => $package['category'],
                    'description' => $package['description'] ?? null,
                    'icon' => $package['icon'] ?? null,
                    'homepage_url' => $package['homepage_url'] ?? null,
                    'install_method' => $package['install_method'],
                    'risk_level' => $package['risk_level'],
                    'requires_reboot' => (bool) $package['requires_reboot'],
                    'requires_third_party_repo' => (bool) $package['requires_third_party_repo'],
                    'is_active' => (bool) $package['is_active'],
                    'is_featured' => (bool) $package['is_featured'],
                    'tags' => $package['tags'] ?? [],
                ]
            );

            $map[$package['slug']] = $model;

            $this->syncPackageVariants($model, $package['variants'] ?? [], $distroMap);
        }

        return $map;
    }

    protected function syncPackageVariants(Package $package, array $variants, array $distroMap): void
    {
        foreach ($variants as $distroSlug => $variant) {
            if (! isset($distroMap[$distroSlug])) {
                throw new RuntimeException("Unknown distro slug '{$distroSlug}' for package '{$package->slug}'");
            }

            PackageVariant::updateOrCreate(
                [
                    'package_id' => $package->id,
                    'distro_id' => $distroMap[$distroSlug]->id,
                ],
                [
                    'package_name' => $variant['package_name'] ?? null,
                    'repository_setup_command' => $variant['repository_setup_command'] ?? null,
                    'pre_install_command' => $variant['pre_install_command'] ?? null,
                    'install_command' => $variant['install_command'] ?? null,
                    'post_install_command' => $variant['post_install_command'] ?? null,
                    'remove_command' => $variant['remove_command'] ?? null,
                    'is_supported' => (bool) $variant['is_supported'],
                ]
            );
        }
    }

    protected function syncProfiles(array $profiles): array
    {
        $map = [];

        foreach ($profiles as $profile) {
            $model = Profile::updateOrCreate(
                ['slug' => $profile['slug']],
                [
                    'name' => $profile['name'],
                    'description' => $profile['description'] ?? null,
                    'icon' => $profile['icon'] ?? null,
                    'is_active' => true,
                ]
            );

            $map[$profile['slug']] = $model;
        }

        return $map;
    }

    protected function syncProfilePackages(array $profiles, array $packageMap, array $profileMap): void
    {
        foreach ($profiles as $profile) {
            $profileModel = $profileMap[$profile['slug']];
            $syncData = [];

            foreach ($profile['packages'] as $packageSlug) {
                if (! isset($packageMap[$packageSlug])) {
                    throw new RuntimeException("Unknown package slug '{$packageSlug}' in profile '{$profile['slug']}'");
                }

                $syncData[$packageMap[$packageSlug]->id] = ['is_default' => true];
            }

            $profileModel->packages()->sync($syncData);
        }
    }

    protected function syncSystemActions(array $systemActions): int
    {
        $count = 0;

        foreach ($systemActions as $action) {
            SystemAction::updateOrCreate(
                ['slug' => $action['slug']],
                [
                    'name' => $action['name'],
                    'description' => $action['description'] ?? null,
                    'input_type' => $action['input_type'],
                    'input_options' => $action['input_options'] ?? null,
                    'validation_rules' => $action['validation_rules'] ?? null,
                    'script_template_ubuntu' => $action['script_template_ubuntu'] ?? null,
                    'script_template_fedora' => $action['script_template_fedora'] ?? null,
                    'is_active' => (bool) ($action['is_active'] ?? true),
                ]
            );

            $count++;
        }

        return $count;
    }

    protected function syncCatalogVersion(?string $version = null): ?CatalogVersion
    {
        if (! $version) {
            return null;
        }

        return CatalogVersion::updateOrCreate(
            ['version' => $version],
            [
                'notes' => 'Catalog synchronized via autom8:sync-catalog',
                'published_at' => now(),
            ]
        );
    }
}
