<?php

namespace App\Providers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        if (app()->environment(['production', 'staging'])) {
            URL::forceScheme('https');

            if (request() instanceof Request) {
                request()->server->set('HTTPS', 'on');
            }
        }
    }
}
