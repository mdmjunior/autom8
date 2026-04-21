<!DOCTYPE html>
<html lang="pt-BR">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AutoM8 Admin</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @livewireStyles
</head>

<body class="min-h-screen bg-zinc-950 text-zinc-100">
    <div class="min-h-screen lg:grid lg:grid-cols-[280px_1fr]">
        <aside class="border-b border-zinc-800 bg-zinc-900 p-6 lg:min-h-screen lg:border-b-0 lg:border-r">
            <div class="mb-8">
                <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">OSLabs</p>
                <h1 class="mt-2 text-2xl font-bold">AutoM8 Admin</h1>
                <p class="mt-2 text-sm text-zinc-400">Gerencie o catálogo da plataforma.</p>
            </div>

            <nav class="space-y-2">
                <a href="{{ route('autom8.admin') }}"
                    class="block rounded-xl px-4 py-3 text-sm font-medium {{ request()->routeIs('autom8.admin') ? 'bg-emerald-500 text-zinc-950' : 'hover:bg-zinc-800' }}">
                    Visão geral
                </a>

                <a href="{{ route('autom8.admin.profiles.index') }}"
                    class="block rounded-xl px-4 py-3 text-sm font-medium {{ request()->routeIs('autom8.admin.profiles.*') ? 'bg-emerald-500 text-zinc-950' : 'hover:bg-zinc-800' }}">
                    Perfis
                </a>

                <a href="{{ route('autom8.admin.packages.index') }}"
                    class="block rounded-xl px-4 py-3 text-sm font-medium {{ request()->routeIs('autom8.admin.packages.*') ? 'bg-emerald-500 text-zinc-950' : 'hover:bg-zinc-800' }}">
                    Pacotes
                </a>

                <a href="{{ route('autom8.landing') }}"
                    class="mt-6 block rounded-xl border border-zinc-700 px-4 py-3 text-sm font-medium hover:bg-zinc-800">
                    Voltar ao site
                </a>
            </nav>
        </aside>

        <main class="p-6 lg:p-10">
            {{ $slot }}
        </main>
    </div>

    @livewireScripts
</body>

</html>