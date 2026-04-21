<?php

namespace App\Livewire\Admin\Packages\Variants;

use App\Models\Distro;
use App\Models\Package;
use App\Models\PackageVariant;
use Livewire\Component;

class Form extends Component
{
    public Package $package;
    public ?PackageVariant $variant = null;

    public string $distro_id = '';
    public string $install_method = '';
    public string $install_command = '';
    public string $remove_command = '';
    public string $notes = '';
    public bool $is_active = true;

    public function mount(Package $package, ?PackageVariant $variant = null): void
    {
        $this->package = $package;

        if ($variant && $variant->exists) {
            $this->variant = $variant;
            $this->distro_id = (string) $variant->distro_id;
            $this->install_method = $variant->install_method;
            $this->install_command = $variant->install_command;
            $this->remove_command = $variant->remove_command ?? '';
            $this->notes = $variant->notes ?? '';
            $this->is_active = (bool) $variant->is_active;
        }
    }

    public function save(): void
    {
        $validated = $this->validate([
            'distro_id' => ['required', 'integer', 'exists:distros,id'],
            'install_method' => ['required', 'string', 'max:255'],
            'install_command' => ['required', 'string'],
            'remove_command' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'is_active' => ['boolean'],
        ], [
            'distro_id.required' => 'Selecione uma distro.',
            'install_method.required' => 'Informe o método de instalação.',
            'install_command.required' => 'Informe o comando de instalação.',
        ]);

        $validated['distro_id'] = (int) $validated['distro_id'];
        $validated['package_id'] = $this->package->id;
        $validated['package_name'] = $this->package->slug;

        $existing = PackageVariant::query()
            ->where('package_id', $this->package->id)
            ->where('distro_id', $validated['distro_id']);

        if ($this->variant) {
            $existing->where('id', '!=', $this->variant->id);
        }

        if ($existing->exists()) {
            $this->addError('distro_id', 'Já existe uma variante para essa distro.');
            return;
        }

        if ($this->variant) {
            $this->variant->update($validated);
            session()->flash('status', 'Variante atualizada com sucesso.');
        } else {
            PackageVariant::query()->create($validated);
            session()->flash('status', 'Variante criada com sucesso.');
        }

        $this->redirectRoute('autom8.admin.packages.variants.index', ['package' => $this->package->id], navigate: true);
    }

    public function render()
    {
        return view('livewire.admin.packages.variants.form', [
            'distros' => Distro::query()->where('is_active', true)->orderBy('name')->get(),
            'installMethods' => ['apt', 'dnf', 'deb', 'rpm', 'flatpak', 'snap', 'script'],
        ])->layout('components.layouts.admin');
    }
}
