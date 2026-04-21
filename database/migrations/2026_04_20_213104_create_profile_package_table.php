<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('profile_package', function (Blueprint $table) {
            $table->id();
            $table->foreignId('profile_id')->constrained()->cascadeOnDelete();
            $table->foreignId('package_id')->constrained()->cascadeOnDelete();
            $table->boolean('is_default')->default(true);
            $table->timestamps();

            $table->unique(['profile_id', 'package_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('profile_package');
    }
};
