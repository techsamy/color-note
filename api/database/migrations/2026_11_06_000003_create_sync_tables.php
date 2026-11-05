<?php

declare(strict_types=1);

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Sharing-ready sync model (ADR 0006): shared note content in `notes`,
 * per-user state in `note_members`, per-user ordered feed in `change_log`.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notes', function (Blueprint $table): void {
            $table->uuid('id')->primary(); // client-generated UUID v7
            $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('type');
            $table->text('title');
            $table->mediumText('body'); // opaque ciphertext when is_locked
            $table->boolean('is_locked')->default(false);
            $table->json('crypto_meta')->nullable();
            $table->date('calendar_date')->nullable();
            $table->unsignedBigInteger('client_created_at');
            $table->unsignedBigInteger('client_updated_at');
            $table->unsignedBigInteger('deleted_at')->nullable(); // trash/tombstone (ms)
            // Deleted forever: content wiped, row kept so other devices delete it too.
            $table->boolean('purged')->default(false);
            $table->unsignedInteger('version')->default(1);
            $table->foreignId('updated_by_device_id')->nullable()->constrained('devices')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('note_members', function (Blueprint $table): void {
            $table->id();
            $table->uuid('note_id');
            $table->foreign('note_id')->references('id')->on('notes')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('permission')->default(0); // 0 owner, 1 editor, 2 viewer
            $table->unsignedTinyInteger('status')->default(1); // 0 pending, 1 active, 2 left/revoked
            // Personal fields (each member has their own).
            $table->unsignedTinyInteger('color')->default(2);
            $table->boolean('is_pinned')->default(false);
            $table->boolean('is_archived')->default(false);
            $table->unsignedBigInteger('reminder_at')->nullable();
            $table->json('reminder_rule')->nullable();
            $table->boolean('reminder_all_day')->default(false);
            $table->boolean('status_bar_pinned')->default(false);
            $table->foreignId('invited_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->unique(['note_id', 'user_id']);
            $table->index(['user_id', 'status']);
        });

        Schema::create('change_log', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('seq');
            $table->string('entity', 20);
            $table->string('entity_id', 40);
            $table->timestamp('created_at')->useCurrent();
            $table->unique(['user_id', 'seq']);
        });

        Schema::create('color_labels', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('color');
            $table->string('label', 50);
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();
            $table->unique(['user_id', 'color']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('color_labels');
        Schema::dropIfExists('change_log');
        Schema::dropIfExists('note_members');
        Schema::dropIfExists('notes');
    }
};
