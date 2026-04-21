<?php

namespace App\Livewire\Admin\Profiles;

use App\Models\Profile;
use Livewire\Component;
use Livewire\WithPagination;

class Index extends Component
{
    use WithPagination;

    public string $search = '';
    public string $status = '';

    protected $queryString = [
        'search' => ['except' => ''],
        'status' => ['except' => ''],
    ];

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function updatingStatus(): void
    {
        $this->resetPage();
    }

    public function clearFilters(): void
    {
        $this->search = '';
        $this->status = '';
        $this->resetPage();
    }

    public function toggleActive(int $profileId): void
    {
        $profile = Profile::query()->findOrFail($profileId);

        $profile->update([
            'is_active' => ! $profile->is_active,
        ]);
    }

    public function render()
    {
        $query = Profile::query()->latest();

        if ($this->search !== '') {
            $query->where(function ($builder) {
                $builder->where('name', 'like', '%' . $this->search . '%')
                    ->orWhere('slug', 'like', '%' . $this->search . '%')
                    ->orWhere('description', 'like', '%' . $this->search . '%');
            });
        }

        if ($this->status !== '') {
            $query->where('is_active', $this->status === 'active');
        }

        return view('livewire.admin.profiles.index', [
            'profiles' => $query->paginate(10),
        ])->layout('components.layouts.admin');
    }
}
