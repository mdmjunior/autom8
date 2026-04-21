<div class="mx-auto max-w-7xl px-6 py-10">
    <div class="mb-8 flex items-center justify-between gap-4">
        <div>
            <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">OSLabs Project</p>
            <h1 class="mt-2 text-4xl font-bold">Histórico de Builds</h1>
            <p class="mt-2 text-zinc-400">Visualize, filtre e gerencie builds gerados pelo AutoM8.</p>
        </div>

        <div class="flex flex-wrap gap-3">
            <a href="{{ route('autom8.wizard') }}"
                class="rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-zinc-950 hover:bg-emerald-400">
                Abrir Wizard
            </a>

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

    <div class="mb-8 rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <div class="grid gap-4 md:grid-cols-[1fr_220px_auto]">
            <div>
                <label class="mb-2 block text-sm text-zinc-400">Buscar</label>
                <input type="text"
                    wire:model.live.debounce.300ms="search"
                    placeholder="UUID, distro, caminho ou hash..."
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Distro</label>
                <select wire:model.live="distro"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                    <option value="">Todas</option>
                    @foreach ($distros as $item)
                    <option value="{{ $item }}">{{ $item }}</option>
                    @endforeach
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
        <div class="mb-6 flex items-center justify-between">
            <h2 class="text-xl font-semibold">Builds encontrados</h2>
            <p class="text-sm text-zinc-500">{{ $builds->total() }} registro(s)</p>
        </div>

        <div class="space-y-4">
            @forelse ($builds as $build)
            <div class="rounded-2xl border border-zinc-800 bg-zinc-950 p-5">
                <div class="grid gap-4 lg:grid-cols-[1fr_auto]">
                    <div class="space-y-2 text-sm">
                        <p class="text-zinc-500">UUID</p>
                        <p class="break-all font-semibold text-zinc-100">{{ $build->uuid }}</p>

                        <div class="grid gap-4 pt-2 md:grid-cols-2">
                            <div>
                                <p class="text-zinc-500">Distro</p>
                                <p class="text-zinc-200">{{ $build->target_distro }}</p>
                            </div>

                            <div>
                                <p class="text-zinc-500">Gerado em</p>
                                <p class="text-zinc-200">{{ optional($build->created_at)->toDateTimeString() }}</p>
                            </div>
                        </div>

                        <div class="pt-2">
                            <p class="text-zinc-500">SHA-256</p>
                            <p class="break-all text-zinc-300">{{ $build->hash_sha256 }}</p>
                        </div>

                        <div class="pt-2">
                            <p class="text-zinc-500">ZIP</p>
                            <p class="break-all text-zinc-400">{{ $build->zip_path }}</p>
                        </div>
                    </div>

                    <div class="flex flex-wrap items-start gap-2 lg:flex-col lg:items-stretch">
                        <a href="{{ route('autom8.builds.download', $build) }}"
                            class="rounded-xl bg-emerald-500 px-4 py-2 text-sm font-semibold text-zinc-950 hover:bg-emerald-400 text-center">
                            Baixar ZIP
                        </a>

                        <a href="{{ route('autom8.wizard', ['from_build' => $build->uuid]) }}"
                            class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800 text-center">
                            Usar como base
                        </a>

                        <button type="button"
                            onclick="navigator.clipboard.writeText(@js($build->hash_sha256))"
                            class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800">
                            Copiar hash
                        </button>

                        <button type="button"
                            onclick="navigator.clipboard.writeText(@js($build->zip_path))"
                            class="rounded-xl border border-zinc-700 px-4 py-2 text-sm font-medium hover:bg-zinc-800">
                            Copiar caminho
                        </button>

                        <button type="button"
                            wire:click="deleteBuild({{ $build->id }})"
                            wire:confirm="Tem certeza que deseja excluir este build?"
                            class="rounded-xl border border-red-500/40 px-4 py-2 text-sm font-medium text-red-300 hover:bg-red-500/10">
                            Excluir
                        </button>

                        <details class="rounded-xl border border-zinc-800 bg-zinc-900 p-3">
                            <summary class="cursor-pointer text-sm font-medium text-zinc-200">
                                Ver detalhes
                            </summary>

                            <div class="mt-3 space-y-3 text-xs text-zinc-300">
                                <div>
                                    <p class="text-zinc-500">Perfis selecionados</p>
                                    <pre class="mt-1 overflow-auto rounded-lg bg-zinc-950 p-3">{{ json_encode($build->selected_profiles_json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</pre>
                                </div>

                                <div>
                                    <p class="text-zinc-500">Pacotes selecionados</p>
                                    <pre class="mt-1 overflow-auto rounded-lg bg-zinc-950 p-3">{{ json_encode($build->selected_packages_json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</pre>
                                </div>

                                <div>
                                    <p class="text-zinc-500">Ações selecionadas</p>
                                    <pre class="mt-1 overflow-auto rounded-lg bg-zinc-950 p-3">{{ json_encode($build->selected_actions_json, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) }}</pre>
                                </div>
                            </div>
                        </details>
                    </div>
                </div>
            </div>
            @empty
            <div class="rounded-2xl border border-zinc-800 bg-zinc-950 p-8 text-center text-zinc-500">
                Nenhum build encontrado.
            </div>
            @endforelse
        </div>

        @if ($builds->hasPages())
        <div class="mt-8">
            {{ $builds->links() }}
        </div>
        @endif
    </div>
</div>