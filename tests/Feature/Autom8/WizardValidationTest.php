<?php

namespace Tests\Feature\Autom8;

use App\Livewire\Autom8\Wizard;
use App\Models\Distro;
use App\Models\SystemAction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class WizardValidationTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_blocks_invalid_hostname(): void
    {
        Distro::create([
            'name' => 'Fedora',
            'slug' => 'fedora',
            'is_active' => true,
        ]);

        SystemAction::create([
            'name' => 'Alterar hostname',
            'slug' => 'set-hostname',
            'description' => 'Set hostname',
            'input_type' => 'text',
            'validation_rules' => 'nullable|string|min:1|max:63',
            'script_template_ubuntu' => 'sudo hostnamectl set-hostname "{{ value }}"',
            'script_template_fedora' => 'sudo hostnamectl set-hostname "{{ value }}"',
            'is_active' => true,
        ]);

        Livewire::test(Wizard::class)
            ->set('selectedDistro', 'fedora')
            ->set('selectedActions', ['set-hostname'])
            ->set('actionInputs.set-hostname', 'invalid host')
            ->call('generatePreview')
            ->assertHasErrors(['actionInputs.set-hostname']);
    }

    public function test_it_blocks_invalid_timezone(): void
    {
        Distro::create([
            'name' => 'Fedora',
            'slug' => 'fedora',
            'is_active' => true,
        ]);

        SystemAction::create([
            'name' => 'Alterar timezone',
            'slug' => 'set-timezone',
            'description' => 'Set timezone',
            'input_type' => 'select',
            'input_options' => ['America/Sao_Paulo', 'UTC'],
            'validation_rules' => 'nullable|string',
            'script_template_ubuntu' => 'sudo timedatectl set-timezone "{{ value }}"',
            'script_template_fedora' => 'sudo timedatectl set-timezone "{{ value }}"',
            'is_active' => true,
        ]);

        Livewire::test(Wizard::class)
            ->set('selectedDistro', 'fedora')
            ->set('selectedActions', ['set-timezone'])
            ->set('actionInputs.set-timezone', 'Mars/Olympus')
            ->call('generatePreview')
            ->assertHasErrors(['actionInputs.set-timezone']);
    }
}
