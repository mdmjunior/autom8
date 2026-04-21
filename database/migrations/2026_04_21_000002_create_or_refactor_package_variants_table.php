<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('package_variants')) {
            Schema::create('package_variants', function (Blueprint $table) {
                $table->id();
                $table->foreignId('package_id')->constrained()->cascadeOnDelete();
                $table->foreignId('distro_id')->constrained()->cascadeOnDelete();
                $table->string('install_method');
                $table->text('install_command');
                $table->text('remove_command')->nullable();
                $table->text('notes')->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();

                $table->unique(['package_id', 'distro_id']);
            });

            return;
        }

        Schema::table('package_variants', function (Blueprint $table) {
            if (! Schema::hasColumn('package_variants', 'install_method')) {
                $table->string('install_method')->after('distro_id');
            }

            if (! Schema::hasColumn('package_variants', 'install_command')) {
                $table->text('install_command')->after('install_method');
            }

            if (! Schema::hasColumn('package_variants', 'remove_command')) {
                $table->text('remove_command')->nullable()->after('install_command');
            }

            if (! Schema::hasColumn('package_variants', 'notes')) {
                $table->text('notes')->nullable()->after('remove_command');
            }

            if (! Schema::hasColumn('package_variants', 'is_active')) {
                $table->boolean('is_active')->default(true)->after('notes');
            }
        });

        try {
            Schema::table('package_variants', function (Blueprint $table) {
                $table->unique(['package_id', 'distro_id']);
            });
        } catch (\Throwable $e) {
            // índice já existe
        }
    }

    public function down(): void
    {
        //
    }
};
