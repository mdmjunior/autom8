<?php

namespace App\Livewire\Admin\Packages;

use App\Models\Package;
use Livewire\Component;
use Livewire\WithPagination;

class Index extends Component
{
    use WithPagination;

    public string $search = '';
    public string $status = '';
    public string $category = '';

    protected $queryString = [
        'search' => ['except' => ''],
        'status' => ['except' => ''],
        'category' => ['except' => ''],
    ];

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function updatingStatus(): void
    {
        $this->resetPage();
    }

    public function updatingCategory(): void
    {
        $this->resetPage();
    }

    public function clearFilters(): void
    {
        $this->search = '';
        $this->status = '';
        $this->category = '';
        $this->resetPage();
    }

    public function toggleActive(int $packageId): void
    {
        $package = Package::query()->findOrFail($packageId);

        $package->update([
            'is_active' => ! $package->is_active,
        ]);
    }

    public function render()
    {
        $query = Package::query()->latest();

        if ($this->search !== '') {
            $query->where(function ($builder) {
                $builder->where('name', 'like', '%' . $this->search . '%')
                    ->orWhere('slug', 'like', '%' . $this->search . '%')
                    ->orWhere('description', 'like', '%' . $this->search . '%')
                    ->orWhere('category', 'like', '%' . $this->search . '%');
            });
        }

        if ($this->status !== '') {
            $query->where('is_active', $this->status === 'active');
        }

        if ($this->category !== '') {
            $query->where('category', $this->category);
        }

        $categories = Package::query()
            ->select('category')
            ->whereNotNull('category')
            ->distinct()
            ->orderBy('category')
            ->pluck('category');

        return view('livewire.admin.packages.index', [
            'packages' => $query->paginate(12),
            'categories' => $categories,
        ])->layout('components.layouts.admin');
    }
}
