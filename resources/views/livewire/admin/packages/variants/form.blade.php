<div class="space-y-8">
    <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
            <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">Administração</p>
            <h2 class="mt-2 text-4xl font-bold">
                {{ $variant ? 'Editar variante' : 'Nova variante' }}
            </h2>
            <p class="mt-3 text-zinc-400">
                Pacote: <span class="font-semibold text-zinc-100">{{ $package->name }}</span>
            </p>
        </div>

        <a href="{{ route('autom8.admin.packages.variants.index', $package) }}"
            class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
            Voltar
        </a>
    </div>

    <form wire:submit="save" class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <div class="grid gap-6">
            <div>
                <label class="mb-2 block text-sm text-zinc-400">Distribuição</label>
                <select wire:model.live="distro_id"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                    <option value="">Selecione</option>
                    @foreach ($distros as $distro)
                    <option value="{{ $distro->id }}">{{ $distro->name }}</option>
                    @endforeach
                </select>
                @error('distro_id') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Método de instalação</label>
                <select wire:model.live="install_method"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                    <option value="">Selecione</option>
                    @foreach ($installMethods as $method)
                    <option value="{{ $method }}">{{ $method }}</option>
                    @endforeach
                </select>
                @error('install_method') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Comando de instalação</label>
                <textarea wire:model.live="install_command"
                    rows="5"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400"></textarea>
                @error('install_command') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Comando de remoção</label>
                <textarea wire:model.live="remove_command"
                    rows="4"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400"></textarea>
                @error('remove_command') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Notas</label>
                <textarea wire:model.live="notes"
                    rows="4"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400"></textarea>
                @error('notes') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div class="flex items-center gap-3">
                <input id="is_active" type="checkbox" wire:model.live="is_active" class="rounded border-zinc-700 bg-zinc-950">
                <label for="is_active" class="text-sm text-zinc-300">Variante ativa</label>
            </div>
        </div>

        <div class="mt-8 flex flex-wrap gap-3">
            <button type="submit"
                class="rounded-xl bg-emerald-500 px-5 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                Salvar variante
            </button>

            <a href="{{ route('autom8.admin.packages.variants.index', $package) }}"
                class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
                Cancelar
            </a>
        </div>
    </form>
</div>