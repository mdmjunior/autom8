<div class="space-y-8">
    <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
            <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">Administração</p>
            <h2 class="mt-2 text-4xl font-bold">Variantes de pacote</h2>
            <p class="mt-3 text-zinc-400">
                Gerencie as variantes do pacote <span class="font-semibold text-zinc-100">{{ $package->name }}</span> por distribuição.
            </p>
        </div>

        <div class="flex flex-wrap gap-3">
            <a href="{{ route('autom8.admin.packages.edit', $package) }}"
                class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
                Editar pacote
            </a>

            <a href="{{ route('autom8.admin.packages.variants.create', $package) }}"
                class="rounded-xl bg-emerald-500 px-5 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                Nova variante
            </a>
        </div>
    </div>

    @if (session('status'))
    <div class="rounded-2xl border border-emerald-500/40 bg-emerald-500/10 p-4 text-emerald-200">
        {{ session('status') }}
    </div>
    @endif

    <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <div class="space-y-4">
            @forelse ($variants as $variant)
            <div class="rounded-2xl border border-zinc-800 bg-zinc-950 p-5">
                <div class="grid gap-4 lg:grid-cols-[1fr_auto]">
                    <div>
                        <div class="flex flex-wrap items-center gap-3">
                            <h3 class="text-xl font-semibold">{{ $variant->distro?->name ?? 'Distro desconhecida' }}</h3>

                            @if ($variant->is_active)
                            <span class="rounded-full bg-emerald-500/15 px-3 py-1 text-xs font-semibold text-emerald-300">
                                Ativa
                            </span>
                            @else
                            <span class="rounded-full bg-zinc-700 px-3 py-1 text-xs font-semibold text-zinc-300">
                                Inativa
                            </span>
                            @endif

                            <span class="rounded-full bg-sky-500/15 px-3 py-1 text-xs font-semibold text-sky-300">
                                {{ $variant->install_method }}
                            </span>
                        </div>

                        <p class="mt-3 text-sm text-zinc-400">Comando de instalação</p>
                        <pre class="mt-2 overflow-x-auto rounded-xl border border-zinc-800 bg-zinc-900 p-4 text-sm text-zinc-200">{{ $variant->install_command }}</pre>

                        @if ($variant->remove_command)
                        <p class="mt-4 text-sm text-zinc-400">Comando de remoção</p>
                        <pre class="mt-2 overflow-x-auto rounded-xl border border-zinc-800 bg-zinc-900 p-4 text-sm text-zinc-200">{{ $variant->remove_command }}</pre>
                        @endif

                        @if ($variant->notes)
                        <p class="mt-4 text-sm text-zinc-400">Notas</p>
                        <p class="mt-2 text-zinc-300">{{ $variant->notes }}</p>
                        @endif
                    </div>

                    <div class="flex flex-wrap items-start gap-2 lg:flex-col lg:items-stretch">
                        <a href="{{ route('autom8.admin.packages.variants.edit', [$package, $variant]) }}"
                            class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800 text-center">
                            Editar
                        </a>

                        <button type="button"
                            wire:click="toggleActive({{ $variant->id }})"
                            class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800">
                            {{ $variant->is_active ? 'Desativar' : 'Ativar' }}
                        </button>
                    </div>
                </div>
            </div>
            @empty
            <div class="rounded-2xl border border-zinc-800 bg-zinc-950 p-8 text-center text-zinc-500">
                Nenhuma variante cadastrada para este pacote.
            </div>
            @endforelse
        </div>
    </div>
</div>