<?php

use App\Models\GeneratedBuild;
use Illuminate\Support\Facades\Route;

Route::redirect('/dashboard', '/projetos/autom8')->name('dashboard');

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('projetos/autom8')->name('autom8.')->group(function () {
    Route::view('/', 'projetos.autom8.landing')->name('landing');
    Route::view('/wizard', 'projetos.autom8.wizard-page')->name('wizard');
    Route::view('/docs', 'projetos.autom8.docs')->name('docs');
    Route::view('/builds', 'projetos.autom8.builds-page')->name('builds.index');

    Route::get('/builds/{build:uuid}/download', function (GeneratedBuild $build) {
        abort_unless($build->zip_path && file_exists($build->zip_path), 404);

        return response()->download(
            $build->zip_path,
            'AutoM8-' . $build->uuid . '.zip'
        );
    })->name('builds.download');
});
