<?php

namespace App\Services\Autom8\Catalog;

use RuntimeException;

class CatalogValidator
{
    public function validate(array $catalog): void
    {
        $this->validateDistros($catalog['distros'] ?? []);
        $this->validatePackages($catalog['packages'] ?? []);
        $this->validateProfiles($catalog['profiles'] ?? [], $catalog['packages'] ?? []);
        $this->validateSystemActions($catalog['system_actions'] ?? []);
    }

    protected function validateDistros(array $distros): void
    {
        $slugs = [];

        foreach ($distros as $index => $distro) {
            $this->assertRequiredKeys($distro, ['name', 'slug', 'is_active'], "distros[{$index}]");

            $slug = $distro['slug'];

            if (in_array($slug, $slugs, true)) {
                throw new RuntimeException("Duplicate distro slug found: {$slug}");
            }

            $slugs[] = $slug;
        }
    }

    protected function validatePackages(array $packages): void
    {
        $packageSlugs = [];

        foreach ($packages as $index => $package) {
            $this->assertRequiredKeys(
                $package,
                [
                    'name',
                    'slug',
                    'category',
                    'install_method',
                    'risk_level',
                    'requires_reboot',
                    'requires_third_party_repo',
                    'is_active',
                    'is_featured',
                    'variants',
                ],
                "packages[{$index}]"
            );

            $slug = $package['slug'];

            if (in_array($slug, $packageSlugs, true)) {
                throw new RuntimeException("Duplicate package slug found: {$slug}");
            }

            $packageSlugs[] = $slug;

            if (! is_array($package['variants']) || empty($package['variants'])) {
                throw new RuntimeException("Package '{$slug}' must define at least one variant.");
            }

            foreach ($package['variants'] as $distroSlug => $variant) {
                if (! is_array($variant)) {
                    throw new RuntimeException("Variant for package '{$slug}' and distro '{$distroSlug}' must be an array.");
                }

                if (! array_key_exists('is_supported', $variant)) {
                    throw new RuntimeException("Variant for package '{$slug}' and distro '{$distroSlug}' must define is_supported.");
                }
            }
        }
    }

    protected function validateProfiles(array $profiles, array $packages): void
    {
        $profileSlugs = [];
        $packageSlugs = array_map(fn($package) => $package['slug'], $packages);

        foreach ($profiles as $index => $profile) {
            $this->assertRequiredKeys(
                $profile,
                ['name', 'slug', 'description', 'icon', 'packages'],
                "profiles[{$index}]"
            );

            $slug = $profile['slug'];

            if (in_array($slug, $profileSlugs, true)) {
                throw new RuntimeException("Duplicate profile slug found: {$slug}");
            }

            $profileSlugs[] = $slug;

            if (! is_array($profile['packages'])) {
                throw new RuntimeException("Profile '{$slug}' packages must be an array.");
            }

            foreach ($profile['packages'] as $packageSlug) {
                if (! in_array($packageSlug, $packageSlugs, true)) {
                    throw new RuntimeException("Profile '{$slug}' references unknown package slug: {$packageSlug}");
                }
            }
        }
    }

    protected function validateSystemActions(array $systemActions): void
    {
        $actionSlugs = [];

        foreach ($systemActions as $index => $action) {
            $this->assertRequiredKeys(
                $action,
                [
                    'name',
                    'slug',
                    'description',
                    'input_type',
                    'validation_rules',
                    'script_template_ubuntu',
                    'script_template_fedora',
                    'is_active',
                ],
                "system_actions[{$index}]"
            );

            $slug = $action['slug'];

            if (in_array($slug, $actionSlugs, true)) {
                throw new RuntimeException("Duplicate system action slug found: {$slug}");
            }

            $actionSlugs[] = $slug;
        }
    }

    protected function assertRequiredKeys(array $data, array $requiredKeys, string $context): void
    {
        foreach ($requiredKeys as $key) {
            if (! array_key_exists($key, $data)) {
                throw new RuntimeException("Missing required key '{$key}' in {$context}");
            }
        }
    }
}
