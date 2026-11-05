<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('devices', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->uuid('device_uuid');
            $table->string('name', 100)->nullable();
            $table->string('platform', 20)->nullable();
            $table->string('app_version', 20)->nullable();
            $table->string('fcm_token')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
            $table->unique(['user_id', 'device_uuid']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('devices');
    }
};
