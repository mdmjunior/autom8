<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_actions', function (Blueprint $table) {
            $table->id();
            $table->string('name', 150);
            $table->string('slug', 150)->unique();
            $table->text('description')->nullable();
            $table->enum('input_type', ['boolean', 'text', 'select'])->default('boolean');
            $table->json('input_options')->nullable();
            $table->string('validation_rules', 255)->nullable();
            $table->text('script_template_ubuntu')->nullable();
            $table->text('script_template_fedora')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('system_actions');
    }
};
