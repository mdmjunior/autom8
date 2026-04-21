<?php

namespace App\Livewire\Admin\Profiles;

use App\Models\Profile;
use Illuminate\Support\Str;
use Livewire\Component;

class Form extends Component
{
    public ?Profile $profile = null;

    public string $name = '';
    public string $slug = '';
    public string $description = '';
    public bool $is_active = true;

    public function mount(?Profile $profile = null): void
    {
        if ($profile && $profile->exists) {
            $this->profile = $profile;
            $this->name = $profile->name;
            $this->slug = $profile->slug;
            $this->description = $profile->description ?? '';
            $this->is_active = (bool) $profile->is_active;
        }
    }

    public function updatedName(string $value): void
    {
        if (! $this->profile) {
            $this->slug = Str::slug($value);
        }
    }

    public function save(): void
    {
        $validated = $this->validate([
            'name' => ['required', 'string', 'max:255'],
            'slug' => ['required', 'string', 'max:255', 'alpha_dash', 'unique:profiles,slug,' . ($this->profile?->id ?? 'NULL')],
            'description' => ['nullable', 'string'],
            'is_active' => ['boolean'],
        ], [
            'slug.alpha_dash' => 'O slug deve conter apenas letras, números, hífens e underscores.',
        ]);

        if ($this->profile) {
            $this->profile->update($validated);
            session()->flash('status', 'Perfil atualizado com sucesso.');
        } else {
            Profile::query()->create($validated);
            session()->flash('status', 'Perfil criado com sucesso.');
        }

        $this->redirectRoute('autom8.admin.profiles.index', navigate: true);
    }

    public function render()
    {
        return view('livewire.admin.profiles.form')->layout('components.layouts.admin');
    }
}
