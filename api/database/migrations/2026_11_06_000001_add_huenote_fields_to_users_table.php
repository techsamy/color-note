<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->uuid('uuid')->nullable()->unique()->after('id');
            $table->string('name')->nullable()->change();
            // Null for Google-only accounts.
            $table->string('password')->nullable()->change();
            $table->string('google_id', 64)->nullable()->unique()->after('email');
            // Last seq in this user's change feed (docs/04 §3).
            $table->unsignedBigInteger('feed_seq')->default(0);
            // Wrapped master key — opaque to the server (docs/03 §3.4).
            $table->json('key_material')->nullable();
            $table->unsignedInteger('key_version')->default(0);
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn(['uuid', 'google_id', 'feed_seq', 'key_material', 'key_version']);
        });
    }
};
