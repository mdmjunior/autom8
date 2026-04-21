<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('package_profile')) {
            return;
        }

        Schema::create('package_profile', function (Blueprint $table) {
            $table->id();
            $table->foreignId('profile_id')->constrained()->cascadeOnDelete();
            $table->foreignId('package_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['profile_id', 'package_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('package_profile');
    }
};
