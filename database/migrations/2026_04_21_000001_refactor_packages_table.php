<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('packages', function (Blueprint $table) {
            if (! Schema::hasColumn('packages', 'website')) {
                $table->string('website')->nullable()->after('slug');
            }

            if (! Schema::hasColumn('packages', 'category')) {
                $table->string('category')->after('website');
            }

            if (! Schema::hasColumn('packages', 'description')) {
                $table->text('description')->nullable()->after('category');
            }

            if (! Schema::hasColumn('packages', 'is_active')) {
                $table->boolean('is_active')->default(true)->after('description');
            }
        });
    }

    public function down(): void
    {
        Schema::table('packages', function (Blueprint $table) {
            if (Schema::hasColumn('packages', 'website')) {
                $table->dropColumn('website');
            }
        });
    }
};
