<div class="space-y-8">
    <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
            <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">Administração</p>
            <h2 class="mt-2 text-4xl font-bold">
                {{ $package ? 'Editar pacote' : 'Novo pacote' }}
            </h2>
            <p class="mt-3 text-zinc-400">
                {{ $package ? 'Atualize os dados do pacote lógico.' : 'Crie um novo pacote lógico para o catálogo.' }}
            </p>
        </div>

        <a href="{{ route('autom8.admin.packages.index') }}"
            class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
            Voltar
        </a>
    </div>

    <form wire:submit="save" class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <div class="grid gap-6">
            <div>
                <label class="mb-2 block text-sm text-zinc-400">Nome do pacote</label>
                <input type="text"
                    wire:model.live="name"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                @error('name') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Slug</label>
                <input type="text"
                    wire:model.live="slug"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                @error('slug') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Website</label>
                <input type="url"
                    wire:model.live="website"
                    placeholder="https://..."
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                @error('website') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Categoria</label>
                <input type="text"
                    wire:model.live="category"
                    placeholder="Ex.: browser, development, media..."
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400">
                @error('category') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div>
                <label class="mb-2 block text-sm text-zinc-400">Descrição</label>
                <textarea wire:model.live="description"
                    rows="5"
                    class="w-full rounded-xl border border-zinc-700 bg-zinc-950 px-4 py-3 text-zinc-100 outline-none focus:border-emerald-400"></textarea>
                @error('description') <p class="mt-2 text-sm text-red-400">{{ $message }}</p> @enderror
            </div>

            <div class="flex items-center gap-3">
                <input id="is_active" type="checkbox" wire:model.live="is_active" class="rounded border-zinc-700 bg-zinc-950">
                <label for="is_active" class="text-sm text-zinc-300">Pacote ativo</label>
            </div>
        </div>

        <div class="mt-8 flex flex-wrap gap-3">
            <button type="submit"
                class="rounded-xl bg-emerald-500 px-5 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                Salvar pacote
            </button>

            <a href="{{ route('autom8.admin.packages.index') }}"
                class="rounded-xl border border-zinc-700 px-5 py-3 font-medium hover:bg-zinc-800">
                Cancelar
            </a>
        </div>
    </form>
</div>