<?php

namespace App\Services\Autom8\Build;

use App\DTO\BuildSelectionData;
use App\Models\Distro;
use App\Models\Package;
use App\Models\Profile;
use App\Models\SystemAction;
use Illuminate\Support\Collection;
use RuntimeException;

class SelectionResolver
{
    public function __construct(
        protected CompatibilityService $compatibilityService
    ) {}

    public function resolve(BuildSelectionData $selection): array
    {
        $distro = Distro::query()
            ->where('slug', $selection->distroSlug)
            ->where('is_active', true)
            ->first();

        if (! $distro) {
            throw new RuntimeException("Selected distro '{$selection->distroSlug}' is invalid or inactive.");
        }

        $profiles = Profile::query()
            ->whereIn('slug', $selection->selectedProfileSlugs)
            ->where('is_active', true)
            ->with('packages.variants.distro')
            ->get();

        $manualPackages = Package::query()
            ->whereIn('slug', $selection->selectedPackageSlugs)
            ->where('is_active', true)
            ->with('variants.distro')
            ->get();

        $systemActions = SystemAction::query()
            ->whereIn('slug', $selection->selectedActionSlugs)
            ->where('is_active', true)
            ->get();

        $profilePackages = $profiles
            ->flatMap(fn(Profile $profile) => $profile->packages)
            ->unique('id')
            ->values();

        $allPackages = $profilePackages
            ->merge($manualPackages)
            ->unique('id')
            ->values();

        $resolvedPackages = [];
        $warnings = [];
        $unsupportedPackages = [];

        /** @var Package $package */
        foreach ($allPackages as $package) {
            $compatibility = $this->compatibilityService->evaluatePackageForDistro($package, $distro->slug);

            foreach ($compatibility['warnings'] as $warning) {
                $warnings[] = $warning;
            }

            if (! $compatibility['supported']) {
                $unsupportedPackages[] = $package->slug;
                continue;
            }

            $variant = $compatibility['variant'];

            $resolvedPackages[] = [
                'id' => $package->id,
                'name' => $package->name,
                'slug' => $package->slug,
                'category' => $package->category,
                'install_method' => $package->install_method,
                'risk_level' => $package->risk_level,
                'requires_reboot' => $package->requires_reboot,
                'requires_third_party_repo' => $package->requires_third_party_repo,
                'variant' => [
                    'id' => $variant?->id,
                    'package_name' => $variant?->package_name,
                    'repository_setup_command' => $variant?->repository_setup_command,
                    'pre_install_command' => $variant?->pre_install_command,
                    'install_command' => $variant?->install_command,
                    'post_install_command' => $variant?->post_install_command,
                    'remove_command' => $variant?->remove_command,
                    'is_supported' => $variant?->is_supported,
                ],
            ];
        }

        $resolvedActions = $systemActions->map(function (SystemAction $action) use ($selection, $distro) {
            $inputValue = $selection->actionInputs[$action->slug] ?? null;

            return [
                'id' => $action->id,
                'name' => $action->name,
                'slug' => $action->slug,
                'description' => $action->description,
                'input_type' => $action->input_type,
                'input_options' => $action->input_options,
                'validation_rules' => $action->validation_rules,
                'input_value' => $inputValue,
                'script_template' => $distro->slug === 'ubuntu'
                    ? $action->script_template_ubuntu
                    : $action->script_template_fedora,
            ];
        })->values()->all();

        return [
            'distro' => [
                'id' => $distro->id,
                'name' => $distro->name,
                'slug' => $distro->slug,
            ],
            'profiles' => $profiles->map(fn(Profile $profile) => [
                'id' => $profile->id,
                'name' => $profile->name,
                'slug' => $profile->slug,
                'description' => $profile->description,
                'icon' => $profile->icon,
            ])->values()->all(),
            'packages' => $resolvedPackages,
            'actions' => $resolvedActions,
            'warnings' => array_values(array_unique($warnings)),
            'unsupported_packages' => array_values(array_unique($unsupportedPackages)),
            'summary' => [
                'selected_profiles_count' => count($selection->selectedProfileSlugs),
                'selected_manual_packages_count' => count($selection->selectedPackageSlugs),
                'resolved_packages_count' => count($resolvedPackages),
                'resolved_actions_count' => count($resolvedActions),
                'warnings_count' => count(array_unique($warnings)),
                'unsupported_packages_count' => count(array_unique($unsupportedPackages)),
            ],
        ];
    }
}
