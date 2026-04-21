<?php

namespace App\Livewire\Autom8;

use App\Models\GeneratedBuild;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Livewire\Component;
use Livewire\WithPagination;

class BuildHistory extends Component
{
    use WithPagination;

    public string $search = '';
    public string $distro = '';

    public ?string $flashMessage = null;
    public ?string $generalError = null;

    protected $queryString = [
        'search' => ['except' => ''],
        'distro' => ['except' => ''],
    ];

    public function updatingSearch(): void
    {
        $this->resetPage();
    }

    public function updatingDistro(): void
    {
        $this->resetPage();
    }

    public function clearFilters(): void
    {
        $this->search = '';
        $this->distro = '';
        $this->resetPage();
        $this->flashMessage = 'Filtros limpos.';
        $this->generalError = null;
    }

    public function deleteBuild(int $buildId): void
    {
        $this->flashMessage = null;
        $this->generalError = null;

        $build = GeneratedBuild::query()->find($buildId);

        if (! $build) {
            $this->generalError = 'Build não encontrado.';
            return;
        }

        $zipPath = $build->zip_path;
        $buildDir = storage_path('app/autom8/builds/' . $build->uuid);

        if ($zipPath && File::exists($zipPath)) {
            File::delete($zipPath);
        }

        if (File::isDirectory($buildDir)) {
            File::deleteDirectory($buildDir);
        }

        Log::info('AutoM8 build deleted from history.', [
            'build_id' => $build->id,
            'uuid' => $build->uuid,
        ]);

        $build->delete();

        $this->flashMessage = 'Build removido com sucesso.';
        $this->resetPage();
    }

    public function render()
    {
        $query = GeneratedBuild::query()->latest();

        if ($this->search !== '') {
            $query->where(function ($q) {
                $q->where('uuid', 'like', '%' . $this->search . '%')
                    ->orWhere('target_distro', 'like', '%' . $this->search . '%')
                    ->orWhere('zip_path', 'like', '%' . $this->search . '%')
                    ->orWhere('hash_sha256', 'like', '%' . $this->search . '%');
            });
        }

        if ($this->distro !== '') {
            $query->where('target_distro', $this->distro);
        }

        $builds = $query->paginate(10);

        $distros = GeneratedBuild::query()
            ->select('target_distro')
            ->distinct()
            ->orderBy('target_distro')
            ->pluck('target_distro');

        return view('livewire.autom8.build-history', [
            'builds' => $builds,
            'distros' => $distros,
        ]);
    }
}
