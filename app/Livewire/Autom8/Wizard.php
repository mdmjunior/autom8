<?php

namespace App\Livewire\Autom8;

use App\DTO\BuildSelectionData;
use App\Models\Distro;
use App\Models\GeneratedBuild;
use App\Models\Package;
use App\Models\Profile;
use App\Models\SystemAction;
use App\Services\Autom8\Build\BuildGeneratorService;
use App\Services\Autom8\Build\SelectionResolver;
use App\Services\Autom8\Support\HostnameSanitizer;
use App\Services\Autom8\Support\TimezoneValidator;
use Livewire\Component;
use Throwable;

class Wizard extends Component
{
    public string $step = 'distro';

    public ?string $selectedDistro = null;
    public array $selectedProfiles = [];
    public array $selectedPackages = [];
    public array $selectedActions = [];
    public array $actionInputs = [];

    public array $preview = [];
    public ?array $generatedBuild = null;

    public string $packageSearch = '';
    public string $packageCategory = '';

    public ?string $generalError = null;
    public ?string $flashMessage = null;

    public ?string $loadFromBuildUuid = null;

    public function mount(): void
    {
        $uuid = request()->query('from_build');

        if (is_string($uuid) && $uuid !== '') {
            $this->loadFromBuildUuid = $uuid;
            $this->loadBuildAsBase($uuid);
        }
    }

    public function goToStep(string $step): void
    {
        $allowed = ['distro', 'profiles', 'packages', 'actions', 'preview', 'result'];

        if (in_array($step, $allowed, true)) {
            $this->step = $step;
            $this->flashMessage = null;
        }
    }

    public function nextStep(): void
    {
        $steps = ['distro', 'profiles', 'packages', 'actions', 'preview', 'result'];
        $currentIndex = array_search($this->step, $steps, true);

        if ($currentIndex === false) {
            $this->step = 'distro';
            return;
        }

        $this->resetErrorBag();
        $this->generalError = null;
        $this->flashMessage = null;

        if ($this->step === 'distro' && empty($this->selectedDistro)) {
            $this->addError('selectedDistro', 'Selecione uma distribuição.');
            return;
        }

        if ($this->step === 'actions') {
            if (! $this->validateSelectedActions()) {
                return;
            }

            $this->generatePreview();

            if ($this->generalError !== null) {
                return;
            }
        }

        if (isset($steps[$currentIndex + 1])) {
            $this->step = $steps[$currentIndex + 1];
        }
    }

    public function previousStep(): void
    {
        $steps = ['distro', 'profiles', 'packages', 'actions', 'preview', 'result'];
        $currentIndex = array_search($this->step, $steps, true);

        if ($currentIndex === false || $currentIndex === 0) {
            $this->step = 'distro';
            return;
        }

        $this->step = $steps[$currentIndex - 1];
        $this->flashMessage = null;
    }

    public function resetWizard(): void
    {
        $this->step = 'distro';
        $this->selectedDistro = null;
        $this->selectedProfiles = [];
        $this->selectedPackages = [];
        $this->selectedActions = [];
        $this->actionInputs = [];
        $this->preview = [];
        $this->generatedBuild = null;
        $this->packageSearch = '';
        $this->packageCategory = '';
        $this->generalError = null;
        $this->flashMessage = 'Wizard reiniciado com sucesso.';
        $this->loadFromBuildUuid = null;
        $this->resetErrorBag();
    }

    public function loadBuildAsBase(string $uuid): void
    {
        $this->resetErrorBag();
        $this->generalError = null;

        $build = GeneratedBuild::query()
            ->where('uuid', $uuid)
            ->first();

        if (! $build) {
            $this->generalError = 'Build base não encontrado.';
            return;
        }

        $selectedActionsJson = is_array($build->selected_actions_json)
            ? $build->selected_actions_json
            : [];

        $this->selectedDistro = $build->target_distro;
        $this->selectedProfiles = is_array($build->selected_profiles_json) ? $build->selected_profiles_json : [];
        $this->selectedPackages = is_array($build->selected_packages_json) ? $build->selected_packages_json : [];
        $this->selectedActions = is_array($selectedActionsJson['slugs'] ?? null) ? $selectedActionsJson['slugs'] : [];
        $this->actionInputs = is_array($selectedActionsJson['inputs'] ?? null) ? $selectedActionsJson['inputs'] : [];

        $this->preview = [];
        $this->generatedBuild = null;
        $this->step = 'preview';
        $this->flashMessage = 'Build carregado como base com sucesso. Revise e gere um novo build.';
        $this->loadFromBuildUuid = $uuid;

        $this->generatePreview();
    }

    public function generatePreview(): void
    {
        $this->resetErrorBag();
        $this->generalError = null;
        $this->flashMessage = null;

        if (! $this->validateSelectedActions()) {
            return;
        }

        try {
            $selection = BuildSelectionData::fromArray([
                'distro_slug' => $this->selectedDistro,
                'selected_profile_slugs' => $this->selectedProfiles,
                'selected_package_slugs' => $this->selectedPackages,
                'selected_action_slugs' => $this->selectedActions,
                'action_inputs' => $this->normalizedActionInputs(),
            ]);

            $this->preview = app(SelectionResolver::class)->resolve($selection);
        } catch (Throwable $e) {
            report($e);
            $this->generalError = 'Não foi possível gerar o preview do build.';
        }
    }

    public function generateBuild(): void
    {
        $this->resetErrorBag();
        $this->generalError = null;
        $this->flashMessage = null;

        if (! $this->validateSelectedActions()) {
            return;
        }

        try {
            $selection = BuildSelectionData::fromArray([
                'distro_slug' => $this->selectedDistro,
                'selected_profile_slugs' => $this->selectedProfiles,
                'selected_package_slugs' => $this->selectedPackages,
                'selected_action_slugs' => $this->selectedActions,
                'action_inputs' => $this->normalizedActionInputs(),
            ]);

            $build = app(BuildGeneratorService::class)->generate($selection);

            $this->generatedBuild = [
                'id' => $build->id,
                'uuid' => $build->uuid,
                'target_distro' => $build->target_distro,
                'zip_path' => $build->zip_path,
                'hash_sha256' => $build->hash_sha256,
                'created_at' => optional($build->created_at)?->toDateTimeString(),
                'download_url' => route('autom8.builds.download', $build),
            ];

            $this->step = 'result';
            $this->flashMessage = 'Build gerado com sucesso.';
        } catch (Throwable $e) {
            report($e);
            $this->generalError = 'Não foi possível gerar o build.';
        }
    }

    protected function validateSelectedActions(): bool
    {
        $actions = SystemAction::query()
            ->whereIn('slug', $this->selectedActions)
            ->where('is_active', true)
            ->get()
            ->keyBy('slug');

        $hostnameSanitizer = app(HostnameSanitizer::class);
        $timezoneValidator = app(TimezoneValidator::class);

        foreach ($this->selectedActions as $slug) {
            $action = $actions->get($slug);

            if (! $action) {
                $this->addError('selectedActions', "A ação '{$slug}' é inválida.");
                return false;
            }

            $value = $this->actionInputs[$slug] ?? null;

            if ($action->input_type === 'boolean') {
                continue;
            }

            if ($action->input_type === 'text') {
                if ($slug === 'set-hostname') {
                    $normalized = $hostnameSanitizer->normalize($value);

                    if (! $hostnameSanitizer->isValid($normalized)) {
                        $this->addError(
                            "actionInputs.{$slug}",
                            'Informe um hostname válido (1 a 63 caracteres, letras, números e hífen, sem espaço nas extremidades).'
                        );
                        return false;
                    }
                } else {
                    if (! is_string($value) || trim($value) === '') {
                        $this->addError("actionInputs.{$slug}", 'Preencha este campo.');
                        return false;
                    }
                }
            }

            if ($action->input_type === 'select') {
                $allowed = is_array($action->input_options) ? $action->input_options : [];
                $normalized = $timezoneValidator->normalize($value);

                if ($slug === 'set-timezone') {
                    if (! $timezoneValidator->isValid($normalized, $allowed)) {
                        $this->addError("actionInputs.{$slug}", 'Selecione um timezone válido.');
                        return false;
                    }
                } else {
                    if (! in_array($normalized, $allowed, true)) {
                        $this->addError("actionInputs.{$slug}", 'Selecione uma opção válida.');
                        return false;
                    }
                }
            }
        }

        return true;
    }

    protected function normalizedActionInputs(): array
    {
        $normalized = [];
        $hostnameSanitizer = app(HostnameSanitizer::class);
        $timezoneValidator = app(TimezoneValidator::class);

        foreach ($this->actionInputs as $slug => $value) {
            if ($slug === 'set-hostname') {
                $normalized[$slug] = $hostnameSanitizer->normalize($value);
                continue;
            }

            if ($slug === 'set-timezone') {
                $normalized[$slug] = $timezoneValidator->normalize($value);
                continue;
            }

            $normalized[$slug] = is_string($value) ? trim($value) : $value;
        }

        return $normalized;
    }

    protected function groupedPreviewPackages(): array
    {
        $packages = $this->preview['packages'] ?? [];

        if (empty($packages)) {
            return [];
        }

        return collect($packages)
            ->groupBy('category')
            ->map(function ($items, $category) {
                return [
                    'category' => $category,
                    'items' => collect($items)->values()->all(),
                ];
            })
            ->values()
            ->all();
    }

    public function render()
    {
        $packagesQuery = Package::query()->where('is_active', true);

        if ($this->packageSearch !== '') {
            $packagesQuery->where(function ($query) {
                $query->where('name', 'like', '%' . $this->packageSearch . '%')
                    ->orWhere('slug', 'like', '%' . $this->packageSearch . '%')
                    ->orWhere('description', 'like', '%' . $this->packageSearch . '%')
                    ->orWhere('category', 'like', '%' . $this->packageSearch . '%');
            });
        }

        if ($this->packageCategory !== '') {
            $packagesQuery->where('category', $this->packageCategory);
        }

        $packages = $packagesQuery
            ->orderBy('category')
            ->orderBy('name')
            ->get();

        $categories = Package::query()
            ->where('is_active', true)
            ->select('category')
            ->distinct()
            ->orderBy('category')
            ->pluck('category');

        $recentBuilds = GeneratedBuild::query()
            ->latest()
            ->limit(10)
            ->get()
            ->map(function (GeneratedBuild $build) {
                return [
                    'id' => $build->id,
                    'uuid' => $build->uuid,
                    'target_distro' => $build->target_distro,
                    'zip_path' => $build->zip_path,
                    'hash_sha256' => $build->hash_sha256,
                    'created_at' => optional($build->created_at)?->toDateTimeString(),
                    'download_url' => route('autom8.builds.download', $build),
                ];
            });

        return view('livewire.autom8.wizard', [
            'distros' => Distro::query()->where('is_active', true)->orderBy('name')->get(),
            'profiles' => Profile::query()->where('is_active', true)->orderBy('name')->get(),
            'packages' => $packages,
            'categories' => $categories,
            'actions' => SystemAction::query()->where('is_active', true)->orderBy('name')->get(),
            'groupedPreviewPackages' => $this->groupedPreviewPackages(),
            'recentBuilds' => $recentBuilds,
        ]);
    }
}
