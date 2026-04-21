<x-layouts.admin>
    <div class="space-y-8">
        <div>
            <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">Painel</p>
            <h2 class="mt-2 text-4xl font-bold">Visão geral do AutoM8 Admin</h2>
            <p class="mt-3 max-w-3xl text-zinc-400">
                Este painel será a base para administrar perfis, pacotes, ações de sistema e versões de catálogo.
            </p>
        </div>

        <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <a href="{{ route('autom8.admin.profiles.index') }}"
                class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6 transition hover:border-emerald-400 hover:bg-zinc-800">
                <p class="text-sm text-zinc-500">Catálogo</p>
                <h3 class="mt-2 text-xl font-semibold">Perfis</h3>
                <p class="mt-2 text-sm text-zinc-400">Crie, edite e ative ou desative perfis do AutoM8.</p>
            </a>

            <a href="{{ route('autom8.admin.packages.index') }}"
                class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6 transition hover:border-emerald-400 hover:bg-zinc-800">
                <p class="text-sm text-zinc-500">Catálogo</p>
                <h3 class="mt-2 text-xl font-semibold">Pacotes</h3>
                <p class="mt-2 text-sm text-zinc-400">Gerencie os pacotes disponíveis por distro.</p>
            </a>

            <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6 opacity-70">
                <p class="text-sm text-zinc-500">Próximo</p>
                <h3 class="mt-2 text-xl font-semibold">Ações</h3>
                <p class="mt-2 text-sm text-zinc-400">Em breve.</p>
            </div>

            <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6 opacity-70">
                <p class="text-sm text-zinc-500">Próximo</p>
                <h3 class="mt-2 text-xl font-semibold">Versões</h3>
                <p class="mt-2 text-sm text-zinc-400">Em breve.</p>
            </div>
        </div>
    </div>
</x-layouts.admin>