<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('generated_builds', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->string('target_distro', 50)->index();
            $table->json('selected_profiles_json')->nullable();
            $table->json('selected_packages_json')->nullable();
            $table->json('selected_actions_json')->nullable();
            $table->json('manifest_json')->nullable();
            $table->string('zip_path', 255)->nullable();
            $table->string('hash_sha256', 64)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('generated_builds');
    }
};
