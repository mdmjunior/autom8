<!DOCTYPE html>
<html lang="pt-BR">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AutoM8 Docs</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>

<body class="min-h-screen bg-zinc-950 text-zinc-100">
    <main class="mx-auto max-w-4xl px-6 py-16">
        <a href="{{ route('autom8.landing') }}" class="text-emerald-400 hover:text-emerald-300">
            ← Voltar
        </a>

        <h1 class="mt-6 text-4xl font-bold">Documentação do AutoM8</h1>

        <div class="mt-8 space-y-4 text-zinc-300">
            <p>O AutoM8 gera pacotes de pós-instalação para distribuições Linux compatíveis.</p>
            <p>Selecione a distro, os perfis, os pacotes e as ações de sistema desejadas.</p>
            <p>No final, um ZIP será gerado contendo scripts e manifesto de build.</p>
        </div>
    </main>
</body>

</html>