<?php

namespace App\Services\Autom8\Build;

use App\DTO\BuildSelectionData;

class ManifestBuilder
{
    public function build(BuildSelectionData $selection, array $resolvedSelection, ?string $catalogVersion = null): array
    {
        return [
            'application' => [
                'name' => 'AutoM8',
                'generated_at' => now()->toIso8601String(),
                'catalog_version' => $catalogVersion,
            ],
            'target' => [
                'distro' => $resolvedSelection['distro'] ?? null,
            ],
            'selection' => [
                'input' => $selection->toArray(),
                'profiles' => $resolvedSelection['profiles'] ?? [],
                'packages' => array_map(function (array $package) {
                    return [
                        'name' => $package['name'],
                        'slug' => $package['slug'],
                        'category' => $package['category'],
                        'install_method' => $package['install_method'],
                        'risk_level' => $package['risk_level'],
                        'requires_reboot' => $package['requires_reboot'],
                        'requires_third_party_repo' => $package['requires_third_party_repo'],
                    ];
                }, $resolvedSelection['packages'] ?? []),
                'actions' => array_map(function (array $action) {
                    return [
                        'name' => $action['name'],
                        'slug' => $action['slug'],
                        'input_type' => $action['input_type'],
                        'input_value' => $action['input_value'],
                    ];
                }, $resolvedSelection['actions'] ?? []),
            ],
            'warnings' => $resolvedSelection['warnings'] ?? [],
            'unsupported_packages' => $resolvedSelection['unsupported_packages'] ?? [],
            'summary' => $resolvedSelection['summary'] ?? [],
        ];
    }
}
