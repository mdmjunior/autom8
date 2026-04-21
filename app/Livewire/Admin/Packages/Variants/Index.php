<?php

namespace App\Livewire\Admin\Packages\Variants;

use App\Models\Package;
use App\Models\PackageVariant;
use Livewire\Component;

class Index extends Component
{
    public Package $package;

    public function mount(Package $package): void
    {
        $this->package = $package;
    }

    public function toggleActive(int $variantId): void
    {
        $variant = PackageVariant::query()
            ->where('package_id', $this->package->id)
            ->findOrFail($variantId);

        $variant->update([
            'is_active' => ! $variant->is_active,
        ]);
    }

    public function render()
    {
        $variants = PackageVariant::query()
            ->with('distro')
            ->where('package_id', $this->package->id)
            ->latest()
            ->get();

        return view('livewire.admin.packages.variants.index', [
            'variants' => $variants,
        ])->layout('components.layouts.admin');
    }
}
