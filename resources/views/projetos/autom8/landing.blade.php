<!DOCTYPE html>
<html lang="pt-BR">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AutoM8</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

<body class="min-h-screen bg-zinc-950 text-zinc-100">
    <main class="mx-auto max-w-6xl px-6 py-16">
        <div class="mb-10">
            <p class="text-sm uppercase tracking-[0.3em] text-emerald-400">OSLabs Project</p>
            <h1 class="mt-3 text-5xl font-bold">AutoM8</h1>
            <p class="mt-4 max-w-3xl text-lg text-zinc-300">
                Geração automatizada de pacotes de pós-instalação para Ubuntu e Fedora.
                Escolha perfis, pacotes e ajustes de sistema. O AutoM8 monta os scripts para você.
            </p>
        </div>

        <div class="grid gap-6 md:grid-cols-3">
            <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
                <h2 class="text-xl font-semibold">Perfis prontos</h2>
                <p class="mt-3 text-zinc-400">
                    Developer, Gamer, Designer e outros perfis editáveis.
                </p>
            </div>

            <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
                <h2 class="text-xl font-semibold">Seleção individual</h2>
                <p class="mt-3 text-zinc-400">
                    Combine pacotes manualmente e personalize o que será incluído.
                </p>
            </div>

            <div class="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
                <h2 class="text-xl font-semibold">Build gerado</h2>
                <p class="mt-3 text-zinc-400">
                    Baixe um ZIP com scripts Bash, manifest e instruções de execução.
                </p>
            </div>
        </div>

        <div class="mt-10 flex flex-wrap gap-4">
            <a href="{{ route('autom8.wizard') }}"
                class="rounded-xl bg-emerald-500 px-6 py-3 font-semibold text-zinc-950 hover:bg-emerald-400">
                Abrir Wizard
            </a>

            <a href="{{ route('autom8.docs') }}"
                class="rounded-xl border border-zinc-700 px-6 py-3 font-semibold text-zinc-100 hover:bg-zinc-800">
                Documentação
            </a>
        </div>
    </main>
</body>

</html>