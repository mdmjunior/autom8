<?php

namespace App\Livewire\Admin\Packages;

use App\Models\Package;
use Illuminate\Support\Str;
use Livewire\Component;

class Form extends Component
{
    public ?Package $package = null;

    public string $name = '';
    public string $slug = '';
    public string $website = '';
    public string $category = '';
    public string $description = '';
    public bool $is_active = true;

    public function mount(?Package $package = null): void
    {
        if ($package && $package->exists) {
            $this->package = $package;
            $this->name = $package->name;
            $this->slug = $package->slug;
            $this->website = $package->website ?? '';
            $this->category = $package->category ?? '';
            $this->description = $package->description ?? '';
            $this->is_active = (bool) $package->is_active;
        }
    }

    public function updatedName(string $value): void
    {
        if (! $this->package) {
            $this->slug = Str::slug($value);
        }
    }

    public function save(): void
    {
        $validated = $this->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:255', 'alpha_dash', 'unique:packages,slug,' . ($this->package?->id ?? 'NULL')],
            'website' => ['nullable', 'url', 'max:255'],
            'category' => ['required', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'is_active' => ['boolean'],
        ], [
            'slug.alpha_dash' => 'O slug deve conter apenas letras, números, hífens e underscores.',
            'category.required' => 'Informe a categoria do pacote.',
            'website.url' => 'Informe uma URL válida para o website.',
        ]);

        if ($this->package) {
            $this->package->update($validated);
            session()->flash('status', 'Pacote atualizado com sucesso.');
        } else {
            $validated['install_method'] = validPackageInstallMethod();
            Package::query()->create($validated);
            session()->flash('status', 'Pacote criado com sucesso.');
        }

        $this->redirectRoute('autom8.admin.packages.index', navigate: true);
    }

    public function render()
    {
        return view('livewire.admin.packages.form')
            ->layout('components.layouts.admin');
    }
}
