<?php

use App\Livewire\Admin\Packages\Form as AdminPackageForm;
use App\Livewire\Admin\Packages\Index as AdminPackagesIndex;
use App\Livewire\Admin\Profiles\Form as AdminProfileForm;
use App\Livewire\Admin\Profiles\Index as AdminProfilesIndex;
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
    Route::view('/admin', 'projetos.autom8.admin-page')->middleware('auth')->name('admin');

    Route::middleware('auth')->prefix('/admin')->name('admin.')->group(function () {
        Route::get('/profiles', AdminProfilesIndex::class)->name('profiles.index');
        Route::get('/profiles/create', AdminProfileForm::class)->name('profiles.create');
        Route::get('/profiles/{profile}/edit', AdminProfileForm::class)->name('profiles.edit');

        Route::get('/packages', AdminPackagesIndex::class)->name('packages.index');
        Route::get('/packages/create', AdminPackageForm::class)->name('packages.create');
        Route::get('/packages/{package}/edit', AdminPackageForm::class)->name('packages.edit');
    });

    Route::get('/builds/{build:uuid}/download', function (GeneratedBuild $build) {
        abort_unless($build->zip_path && file_exists($build->zip_path), 404);

        return response()->download(
            $build->zip_path,
            'AutoM8-' . $build->uuid . '.zip'
        );
    })->name('builds.download');
});
