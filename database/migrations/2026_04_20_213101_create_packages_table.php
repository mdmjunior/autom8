<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('packages', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->string('slug', 150)->unique();
            $table->string('category', 100)->index();
            $table->text('description')->nullable();
            $table->string('icon', 255)->nullable();
            $table->string('homepage_url', 255)->nullable();
            $table->enum('install_method', ['apt', 'dnf', 'flatpak', 'script', 'manual']);
            $table->enum('risk_level', ['low', 'medium', 'high'])->default('low');
            $table->boolean('requires_reboot')->default(false);
            $table->boolean('requires_third_party_repo')->default(false);
            $table->boolean('is_active')->default(true);
            $table->boolean('is_featured')->default(false);
            $table->json('tags')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('packages');
    }
};
