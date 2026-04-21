<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('package_variants', function (Blueprint $table) {
            $table->id();
            $table->foreignId('package_id')->constrained()->cascadeOnDelete();
            $table->foreignId('distro_id')->constrained()->cascadeOnDelete();
            $table->string('package_name', 150)->nullable();
            $table->text('repository_setup_command')->nullable();
            $table->text('pre_install_command')->nullable();
            $table->text('install_command')->nullable();
            $table->text('post_install_command')->nullable();
            $table->text('remove_command')->nullable();
            $table->boolean('is_supported')->default(true);
            $table->timestamps();

            $table->unique(['package_id', 'distro_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('package_variants');
    }
};
