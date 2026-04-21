<?php

namespace App\Services\Autom8\Build;

use App\Models\Package;
use App\Models\PackageVariant;

class CompatibilityService
{
    public function evaluatePackageForDistro(Package $package, string $distroSlug): array
    {
        /** @var PackageVariant|null $variant */
        $variant = $package->variants
            ->first(fn(PackageVariant $variant) => $variant->distro?->slug === $distroSlug);

        if (! $variant) {
            return [
                'supported' => false,
                'warnings' => [
                    "Package '{$package->slug}' does not define a variant for distro '{$distroSlug}'.",
                ],
                'variant' => null,
            ];
        }

        $warnings = [];

        if (! $variant->is_supported) {
            $warnings[] = "Package '{$package->slug}' is marked as unsupported for distro '{$distroSlug}'.";
        }

        if ($package->requires_third_party_repo) {
            $warnings[] = "Package '{$package->slug}' requires a third-party repository.";
        }

        if ($package->requires_reboot) {
            $warnings[] = "Package '{$package->slug}' may require a reboot after installation.";
        }

        if ($package->risk_level !== 'low') {
            $warnings[] = "Package '{$package->slug}' has risk level '{$package->risk_level}'.";
        }

        return [
            'supported' => (bool) $variant->is_supported,
            'warnings' => $warnings,
            'variant' => $variant,
        ];
    }
}
