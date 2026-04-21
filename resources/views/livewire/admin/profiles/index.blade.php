<div class="space-y-8">
    <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
            <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">Administração</p>
            <h2 class="mt-2 text-4xl font-bold">Perfis</h2>
            <p class="mt-3 text-zinc-400">Gerencie os perfis disponíveis no catálogo do AutoM8.</p>
        </div>

        <a href="{{ route('autom8.admin.profiles.create') }}"
            class="rounded-xl bg-emerald-500 px-5 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
            Novo perfil
        </a>
    </div>

    @if (session('status'))
    <div class="rounded-2xl border border-emerald-500/40 bg-emerald-500/10 p-4 text-emerald-200">
        {{ session('status') }}
    </div>
    @endif

    <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <div class="grid gap-4 md:grid-cols-[1fr_220px_auto]">
            <div>
                <label class="mb-2 block text-sm text-zinc-400">Buscar</label>
                <input type="text"
                    wire:model.live.debounce.300ms="search"
                    placeholder="Nome, slug ou descrição..."
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Status</label>
                <select wire:model.live="status"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                    <option value="">Todos</option>
                    <option value="active">Ativos</option>
                    <option value="inactive">Inativos</option>
                </select>
            </div>

            <div class="flex items-end">
                <button type="button"
                    wire:click="clearFilters"
                    class="w-full rounded-xl border border-zinc-700 px-4 py-3 font-medium hover:bg-zinc-800">
                    Limpar filtros
                </button>
            </div>
        </div>
    </div>

    <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <div class="space-y-4">
            @forelse ($profiles as $profile)
            <div class="rounded-2xl border border-zinc-800 bg-zinc-950 p-5">
                <div class="grid gap-4 lg:grid-cols-[1fr_auto]">
                    <div>
                        <div class="flex flex-wrap items-center gap-3">
                            <h3 class="text-xl font-semibold">{{ $profile->name }}</h3>

                            @if ($profile->is_active)
                            <span class="rounded-full bg-emerald-500/15 px-3 py-1 text-xs font-semibold text-emerald-300">
                                Ativo
                            </span>
                            @else
                            <span class="rounded-full bg-zinc-700 px-3 py-1 text-xs font-semibold text-zinc-300">
                                Inativo
                            </span>
                            @endif
                        </div>

                        <p class="mt-2 text-sm uppercase tracking-wide text-emerald-400">{{ $profile->slug }}</p>
                        <p class="mt-3 text-zinc-400">{{ $profile->description ?: 'Sem descrição.' }}</p>
                    </div>

                    <div class="flex flex-wrap items-start gap-2 lg:flex-col lg:items-stretch">
                        <a href="{{ route('autom8.admin.profiles.edit', $profile) }}"
                            class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800 text-center">
                            Editar
                        </a>

                        <button type="button"
                            wire:click="toggleActive({{ $profile->id }})"
                            class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800">
                            {{ $profile->is_active ? 'Desativar' : 'Ativar' }}
                        </button>
                    </div>
                </div>
            </div>
            @empty
            <div class="rounded-2xl border border-zinc-800 bg-zinc-950 p-8 text-center text-zinc-500">
                Nenhum perfil encontrado.
            </div>
            @endforelse
        </div>

        @if ($profiles->hasPages())
        <div class="mt-8">
            {{ $profiles->links() }}
        </div>
        @endif
    </div>
</div>