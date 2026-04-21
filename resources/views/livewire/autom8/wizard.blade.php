<div class="mx-auto max-w-7xl px-6 py-10">
    <div class="mb-8 flex items-center justify-between gap-4">
        <div>
            <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">OSLabs Project</p>
            <h1 class="mt-2 text-4xl font-bold">AutoM8 Wizard</h1>
            <p class="mt-2 text-zinc-400">Monte um pacote de pós-instalação para Ubuntu ou Fedora.</p>
        </div>

        <div class="flex flex-wrap gap-3">
            <button type="button"
                wire:click="resetWizard"
                class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800">
                Reiniciar wizard
            </button>

            <a href="{{ route('autom8.landing') }}"
                class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800">
                Voltar
            </a>
        </div>
    </div>

    @if ($flashMessage)
    <div class="mb-6 rounded-2xl border border-emerald-500/40 bg-emerald-500/10 p-4 text-emerald-200">
        {{ $flashMessage }}
    </div>
    @endif

    @if ($generalError)
    <div class="mb-6 rounded-2xl border border-red-500/40 bg-red-500/10 p-4 text-red-200">
        {{ $generalError }}
    </div>
    @endif

    <div class="mb-8 flex flex-wrap gap-2">
        @foreach (['distro' => 'Distro', 'profiles' => 'Perfis', 'packages' => 'Pacotes', 'actions' => 'Ações', 'preview' => 'Preview', 'result' => 'Resultado'] as $key => $label)
        <button type="button"
            wire:click="goToStep('{{ $key }}')"
            class="rounded-lg px-4 py-2 text-sm font-medium {{ $step === $key ? 'bg-emerald-500 text-zinc-950' : 'border border-zinc-800 bg-zinc-900 text-zinc-200' }}">
            {{ $label }}
        </button>
        @endforeach
    </div>

    <div class="grid gap-8 lg:grid-cols-[1.2fr_0.8fr]">
        <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
            @if ($step === 'distro')
            <h2 class="text-2xl font-semibold">Escolha a distribuição</h2>
            <p class="mt-2 text-zinc-400">Selecione a base do build.</p>

            <div class="mt-6 grid gap-4 md:grid-cols-2">
                @foreach ($distros as $distro)
                <label class="cursor-pointer rounded-2xl border p-5 {{ $selectedDistro === $distro->slug ? 'border-emerald-400 bg-zinc-800' : 'border-zinc-800 bg-zinc-950' }}">
                    <input type="radio" class="hidden" wire:model.live="selectedDistro" value="{{ $distro->slug }}">
                    <div class="text-xl font-semibold">{{ $distro->name }}</div>
                    <div class="mt-2 text-sm text-zinc-400">{{ $distro->slug }}</div>
                </label>
                @endforeach
            </div>

            @error('selectedDistro')
            <p class="mt-4 text-sm text-red-400">{{ $message }}</p>
            @enderror
            @endif

            @if ($step === 'profiles')
            <h2 class="text-2xl font-semibold">Escolha perfis</h2>
            <p class="mt-2 text-zinc-400">Selecione um ou mais perfis base.</p>

            <div class="mt-6 grid gap-4 md:grid-cols-2">
                @foreach ($profiles as $profile)
                <label class="cursor-pointer rounded-2xl border p-5 {{ in_array($profile->slug, $selectedProfiles, true) ? 'border-emerald-400 bg-zinc-800' : 'border-zinc-800 bg-zinc-950' }}">
                    <div class="flex items-start gap-3">
                        <input type="checkbox" wire:model.live="selectedProfiles" value="{{ $profile->slug }}" class="mt-1">
                        <div>
                            <div class="text-lg font-semibold">{{ $profile->name }}</div>
                            <div class="mt-2 text-sm text-zinc-400">{{ $profile->description }}</div>
                        </div>
                    </div>
                </label>
                @endforeach
            </div>
            @endif

            @if ($step === 'packages')
            <h2 class="text-2xl font-semibold">Escolha pacotes</h2>
            <p class="mt-2 text-zinc-400">Adicione pacotes extras além dos perfis.</p>

            <div class="mt-6 grid gap-4 md:grid-cols-2">
                <div>
                    <label class="mb-2 block text-sm text-zinc-400">Buscar pacote</label>
                    <input type="text"
                        wire:model.live.debounce.300ms="packageSearch"
                        placeholder="Ex.: docker, git, vlc..."
                        class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                </div>

                <div>
                    <label class="mb-2 block text-sm text-zinc-400">Filtrar por categoria</label>
                    <select wire:model.live="packageCategory"
                        class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                        <option value="">Todas as categorias</option>
                        @foreach ($categories as $category)
                        <option value="{{ $category }}">{{ $category }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <p class="mt-6 text-sm text-zinc-500">
                {{ $packages->count() }} pacote(s) encontrado(s)
            </p>

            <div class="mt-4 grid gap-4 md:grid-cols-2">
                @foreach ($packages as $package)
                <label class="cursor-pointer rounded-2xl border p-5 {{ in_array($package->slug, $selectedPackages, true) ? 'border-emerald-400 bg-zinc-800' : 'border-zinc-800 bg-zinc-950' }}">
                    <div class="flex items-start gap-3">
                        <input type="checkbox" wire:model.live="selectedPackages" value="{{ $package->slug }}" class="mt-1">
                        <div>
                            <div class="text-lg font-semibold">{{ $package->name }}</div>
                            <div class="mt-1 text-xs uppercase tracking-wide text-emerald-400">{{ $package->category }}</div>
                            <div class="mt-2 text-sm text-zinc-400">{{ $package->description }}</div>
                        </div>
                    </div>
                </label>
                @endforeach
            </div>
            @endif

            @if ($step === 'actions')
            <h2 class="text-2xl font-semibold">Escolha ações de sistema</h2>
            <p class="mt-2 text-zinc-400">Defina ajustes além da instalação de pacotes.</p>

            <div class="mt-6 space-y-4">
                @foreach ($actions as $action)
                <div class="rounded-2xl border border-zinc-800 bg-zinc-950 p-5">
                    <label class="flex items-start gap-3">
                        <input type="checkbox" wire:model.live="selectedActions" value="{{ $action->slug }}" class="mt-1">
                        <div class="w-full">
                            <div class="text-lg font-semibold">{{ $action->name }}</div>
                            <div class="mt-2 text-sm text-zinc-400">{{ $action->description }}</div>

                            @if (in_array($action->slug, $selectedActions, true))
                            <div class="mt-4">
                                @if ($action->input_type === 'text')
                                <input type="text"
                                    wire:model.live="actionInputs.{{ $action->slug }}"
                                    placeholder="Digite o valor"
                                    class="w-full rounded-xl border border-zinc-700 bg-zinc-900 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                                @elseif ($action->input_type === 'select')
                                <select wire:model.live="actionInputs.{{ $action->slug }}"
                                    class="w-full rounded-xl border border-zinc-700 bg-zinc-900 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                                    <option value="">Selecione...</option>
                                    @foreach (($action->input_options ?? []) as $option)
                                    <option value="{{ $option }}">{{ $option }}</option>
                                    @endforeach
                                </select>
                                @endif

                                @error("actionInputs.{$action->slug}")
                                <p class="mt-3 text-sm text-red-400">{{ $message }}</p>
                                @enderror
                            </div>
                            @endif
                        </div>
                    </label>
                </div>
                @endforeach
            </div>

            @error('selectedActions')
            <p class="mt-4 text-sm text-red-400">{{ $message }}</p>
            @enderror
            @endif

            @if ($step === 'preview')
            <h2 class="text-2xl font-semibold">Preview do build</h2>
            <p class="mt-2 text-zinc-400">Confira o que será gerado pelo AutoM8.</p>

            <div class="mt-6 space-y-6">
                <div>
                    <h3 class="text-lg font-semibold">Distro</h3>
                    <p class="mt-2 text-zinc-300">{{ $preview['distro']['name'] ?? '-' }}</p>
                </div>

                <div>
                    <h3 class="text-lg font-semibold">Perfis</h3>
                    <ul class="mt-2 space-y-2 text-zinc-300">
                        @forelse (($preview['profiles'] ?? []) as $profile)
                        <li>• {{ $profile['name'] }}</li>
                        @empty
                        <li class="text-zinc-500">Nenhum perfil selecionado</li>
                        @endforelse
                    </ul>
                </div>

                <div>
                    <h3 class="text-lg font-semibold">Pacotes por categoria</h3>

                    @forelse ($groupedPreviewPackages as $group)
                    <div class="mt-4 rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                        <p class="text-sm font-semibold uppercase tracking-wide text-emerald-400">
                            {{ $group['category'] }}
                        </p>

                        <ul class="mt-3 space-y-2 text-zinc-300">
                            @foreach ($group['items'] as $package)
                            <li>• {{ $package['name'] }} <span class="text-zinc-500">({{ $package['slug'] }})</span></li>
                            @endforeach
                        </ul>
                    </div>
                    @empty
                    <p class="mt-2 text-zinc-500">Nenhum pacote resolvido</p>
                    @endforelse
                </div>

                <div>
                    <h3 class="text-lg font-semibold">Ações</h3>
                    <ul class="mt-2 space-y-2 text-zinc-300">
                        @forelse (($preview['actions'] ?? []) as $action)
                        <li>• {{ $action['name'] }}</li>
                        @empty
                        <li class="text-zinc-500">Nenhuma ação selecionada</li>
                        @endforelse
                    </ul>
                </div>

                <div>
                    <h3 class="text-lg font-semibold">Warnings</h3>
                    <ul class="mt-2 space-y-2 text-yellow-300">
                        @forelse (($preview['warnings'] ?? []) as $warning)
                        <li>• {{ $warning }}</li>
                        @empty
                        <li class="text-zinc-500">Sem warnings</li>
                        @endforelse
                    </ul>
                </div>

                <div>
                    <h3 class="text-lg font-semibold">Resumo técnico</h3>
                    <div class="mt-3 grid gap-3 sm:grid-cols-2">
                        <div class="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                            <p class="text-sm text-zinc-500">Perfis selecionados</p>
                            <p class="mt-1 text-xl font-semibold text-zinc-100">{{ $preview['summary']['selected_profiles_count'] ?? 0 }}</p>
                        </div>

                        <div class="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                            <p class="text-sm text-zinc-500">Pacotes manuais</p>
                            <p class="mt-1 text-xl font-semibold text-zinc-100">{{ $preview['summary']['selected_manual_packages_count'] ?? 0 }}</p>
                        </div>

                        <div class="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                            <p class="text-sm text-zinc-500">Pacotes resolvidos</p>
                            <p class="mt-1 text-xl font-semibold text-zinc-100">{{ $preview['summary']['resolved_packages_count'] ?? 0 }}</p>
                        </div>

                        <div class="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                            <p class="text-sm text-zinc-500">Warnings</p>
                            <p class="mt-1 text-xl font-semibold text-yellow-300">{{ $preview['summary']['warnings_count'] ?? 0 }}</p>
                        </div>
                    </div>
                </div>
            </div>
            @endif

            @if ($step === 'result')
            <h2 class="text-2xl font-semibold">Build gerado</h2>
            <p class="mt-2 text-zinc-400">O pacote foi gerado com sucesso.</p>

            <div class="mt-6 rounded-2xl border border-emerald-500/40 bg-emerald-500/10 p-5">
                <div class="space-y-2 break-all text-sm text-zinc-200">
                    <p><strong>ID:</strong> {{ $generatedBuild['id'] ?? '-' }}</p>
                    <p><strong>UUID:</strong> {{ $generatedBuild['uuid'] ?? '-' }}</p>
                    <p><strong>Distro:</strong> {{ $generatedBuild['target_distro'] ?? '-' }}</p>
                    <p><strong>ZIP:</strong> {{ $generatedBuild['zip_path'] ?? '-' }}</p>
                    <p><strong>SHA-256:</strong> {{ $generatedBuild['hash_sha256'] ?? '-' }}</p>
                    <p><strong>Gerado em:</strong> {{ $generatedBuild['created_at'] ?? '-' }}</p>
                </div>
            </div>

            @if (!empty($generatedBuild['download_url']))
            <div class="mt-6 flex flex-wrap gap-3">
                <a href="{{ $generatedBuild['download_url'] }}"
                    class="inline-flex rounded-xl bg-emerald-500 px-5 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                    Baixar ZIP
                </a>

                <button type="button"
                    onclick="navigator.clipboard.writeText(@js($generatedBuild['hash_sha256'] ?? ''))"
                    class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
                    Copiar hash
                </button>

                <button type="button"
                    onclick="navigator.clipboard.writeText(@js($generatedBuild['zip_path'] ?? ''))"
                    class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
                    Copiar caminho do ZIP
                </button>
            </div>
            @endif
            @endif

            <div class="mt-8 flex flex-wrap gap-3">
                @if ($step !== 'distro')
                <button type="button"
                    wire:click="previousStep"
                    class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
                    Voltar
                </button>
                @endif

                @if (!in_array($step, ['preview', 'result'], true))
                <button type="button"
                    wire:click="nextStep"
                    class="rounded-xl bg-emerald-500 px-5 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                    Próximo
                </button>
                @endif

                @if ($step === 'preview')
                <button type="button"
                    wire:click="generateBuild"
                    class="rounded-xl bg-emerald-500 px-5 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                    Gerar build
                </button>
                @endif
            </div>
        </div>

        <aside class="space-y-8">
            <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
                <h2 class="text-xl font-semibold">Resumo atual</h2>

                <div class="mt-6 space-y-5 text-sm">
                    <div>
                        <p class="text-zinc-500">Distro</p>
                        <p class="mt-1 text-zinc-100">{{ $selectedDistro ?: 'Não selecionada' }}</p>
                    </div>

                    <div>
                        <p class="text-zinc-500">Perfis</p>
                        <p class="mt-1 text-zinc-100">{{ count($selectedProfiles) }}</p>
                    </div>

                    <div>
                        <p class="text-zinc-500">Pacotes manuais</p>
                        <p class="mt-1 text-zinc-100">{{ count($selectedPackages) }}</p>
                    </div>

                    <div>
                        <p class="text-zinc-500">Ações</p>
                        <p class="mt-1 text-zinc-100">{{ count($selectedActions) }}</p>
                    </div>

                    @if (!empty($preview))
                    <div>
                        <p class="text-zinc-500">Pacotes resolvidos</p>
                        <p class="mt-1 text-zinc-100">{{ $preview['summary']['resolved_packages_count'] ?? 0 }}</p>
                    </div>

                    <div>
                        <p class="text-zinc-500">Warnings</p>
                        <p class="mt-1 text-yellow-300">{{ $preview['summary']['warnings_count'] ?? 0 }}</p>
                    </div>
                    @endif
                </div>
            </div>

            <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
                <h2 class="text-xl font-semibold">Histórico recente</h2>

                <div class="mt-6 space-y-4">
                    @forelse ($recentBuilds as $build)
                    <div class="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                        <div class="space-y-1 text-sm">
                            <p class="font-semibold text-zinc-100">{{ $build['uuid'] }}</p>
                            <p class="text-zinc-400">Distro: {{ $build['target_distro'] }}</p>
                            <p class="text-zinc-500">Gerado em: {{ $build['created_at'] }}</p>
                        </div>

                        <div class="mt-4 flex flex-wrap gap-2">
                            <a href="{{ $build['download_url'] }}"
                                class="rounded-lg bg-emerald-500 px-3 py-2 text-xs font-semibold text-zinc-950 hover:bg-emerald-400">
                                Baixar
                            </a>

                            <button type="button"
                                onclick="navigator.clipboard.writeText(@js($build['hash_sha256']))"
                                class="rounded-lg border border-zinc-700 px-3 py-2 text-xs font-medium hover:bg-zinc-800">
                                Copiar hash
                            </button>
                        </div>
                    </div>
                    @empty
                    <p class="text-sm text-zinc-500">Nenhum build recente.</p>
                    @endforelse
                </div>
            </div>
        </aside>
    </div>
</div>