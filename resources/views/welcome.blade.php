<!DOCTYPE html>
<html lang="pt-BR">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AutoM8</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

<body class="min-h-screen bg-zinc-950 text-zinc-100">
    <main class="mx-auto max-w-5xl px-6 py-16">
        <p class="text-sm uppercase tracking-[0.25em] text-emerald-400">OSLabs Project</p>
        <h1 class="mt-3 text-5xl font-bold">AutoM8</h1>
        <p class="mt-4 text-zinc-300">
            Ferramenta de pós-instalação para Ubuntu e Fedora.
        </p>

        <div class="mt-8 flex gap-4">
            <a href="{{ route('autom8.landing') }}"
                class="rounded-xl bg-emerald-500 px-6 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                Ir para AutoM8
            </a>

            <a href="{{ route('autom8.wizard') }}"
                class="rounded-xl border border-zinc-700 px-6 py-3 font-semibold text-zinc-100 hover:bg-zinc-800">
                Abrir Wizard
            </a>
        </div>
    </main>
</body>

</html>