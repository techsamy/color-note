import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/core/crypto/crypto_service.dart';
import 'package:huenote/core/utils/clock.dart';
import 'package:huenote/core/widgets/dialogs.dart';
import 'package:huenote/core/widgets/password_field.dart';
import 'package:huenote/features/backup/backup_controller.dart';
import 'package:huenote/features/backup/data/backup_service.dart';
import 'package:huenote/features/backup/data/export_service.dart';
import 'package:huenote/features/lock/domain/master_key_service.dart';
import 'package:huenote/features/lock/presentation/unlock_dialog.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// FR-B1 — manual encrypted backup & restore.
/// (Scheduled auto-backup needs background work on a real phone: step 9.)
class BackupScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  String? _busy;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  BackupController get _ctrl => ref.read(backupControllerProvider);

  Future<void> _create() async {
    final password = await _askPassword(
      title: _l10n.backupCreate,
      label: _l10n.backupPassword,
      hint: _l10n.backupPasswordHint,
      confirm: true,
    );
    if (password == null) return;
    setState(() => _busy = _l10n.backupWorking);
    try {
      final bytes = await _ctrl.createBackup(password);
      final date = DateFormat('yyyy-MM-dd')
          .format(ref.read(clockProvider).now().toLocal());
      final saved = await FilePicker.saveFile(
        fileName: 'huenote-backup-$date.${BackupService.fileExtension}',
        bytes: bytes,
      );
      if (mounted && saved != null) showSnack(context, _l10n.backupSaved);
    } on Object catch (e) {
      debugPrint('Backup failed: $e');
      if (mounted) showSnack(context, _l10n.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _export() async {
    final notes = await ref.read(notesRepositoryProvider).allNotes();
    final now = ref.read(clockProvider).now();
    final bytes = const ExportService().export(notes, now: now);
    final date = DateFormat('yyyy-MM-dd').format(now.toLocal());
    final saved = await FilePicker.saveFile(
      fileName: 'huenote-export-$date.zip',
      bytes: bytes,
      mimeType: 'application/zip',
    );
    if (mounted && saved != null) showSnack(context, _l10n.exportSaved);
  }

  Future<void> _restore() async {
    final file = await FilePicker.pickFile();
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final password = await _askPassword(
      title: _l10n.backupRestore,
      label: _l10n.backupPassword,
    );
    if (password == null) return;
    setState(() => _busy = _l10n.restoreWorking);
    try {
      final contents = await _ctrl.open(bytes, password);
      var outcome = await _ctrl.restore(contents);
      while (outcome is! RestoreDone) {
        if (!mounted) return;
        // Locked notes from another device: unlock here, then ask for the
        // master password that was used there.
        if (!await ensureUnlocked(context, ref) || !mounted) return;
        final old = await _askPassword(
          title: _l10n.backupRestore,
          label: _l10n.oldMasterPassword,
          hint: outcome is RestoreWrongMasterPassword
              ? _l10n.wrongPassword
              : _l10n.restoreNeedsOldMasterPassword,
        );
        if (old == null) return;
        outcome = await _ctrl.restore(contents, backupMasterPassword: old);
      }
      if (!mounted) return;
      final r = outcome.result;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_l10n.restoreDone),
          content: Text(_l10n.restoreSummary(r.added, r.updated, r.skipped)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_l10n.actionOk),
            ),
          ],
        ),
      );
    } on WrongKeyException {
      if (mounted) showSnack(context, _l10n.backupWrongPassword);
    } on InvalidBackupException catch (e) {
      if (!mounted) return;
      showSnack(
        context,
        e.reason.contains('newer') ? _l10n.backupNewer : _l10n.backupInvalid,
      );
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<String?> _askPassword({
    required String title,
    required String label,
    String? hint,
    bool confirm = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _PasswordDialog(
        title: title,
        label: label,
        hint: hint,
        confirm: confirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(l10n.backupInfo),
          const SizedBox(height: AppSpacing.xl),
          if (_busy != null) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
            Text(_busy!),
            const SizedBox(height: AppSpacing.lg),
          ],
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(l10n.backupCreate),
              subtitle: Text(l10n.backupCreateHint),
              enabled: _busy == null,
              onTap: _create,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.exportTitle),
              subtitle: Text(l10n.exportHint),
              enabled: _busy == null,
              onTap: _export,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: Text(l10n.backupRestore),
              subtitle: Text(l10n.backupRestoreHint),
              enabled: _busy == null,
              onTap: _restore,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const new({
    required this.title,
    required this.label,
    required this.confirm,
    this.hint,
  });

  final String title;
  final String label;
  final String? hint;
  final bool confirm;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  final _again = TextEditingController();
  String? _error;
  String? _againError;

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    const min = MasterKeyService.minPasswordLength;
    setState(() {
      _error = widget.confirm && _password.text.length < min
          ? l10n.passwordTooShort(min)
          : (_password.text.isEmpty ? l10n.wrongPassword : null);
      _againError = widget.confirm && _again.text != _password.text
          ? l10n.passwordsDontMatch
          : null;
    });
    if (_error == null && _againError == null) {
      Navigator.pop(context, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.hint != null) ...[
            Text(widget.hint!),
            const SizedBox(height: AppSpacing.lg),
          ],
          PasswordField(
            controller: _password,
            label: widget.label,
            errorText: _error,
            autofocus: true,
            textInputAction: widget.confirm
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: widget.confirm ? null : (_) => _submit(),
          ),
          if (widget.confirm) ...[
            const SizedBox(height: AppSpacing.lg),
            PasswordField(
              controller: _again,
              label: l10n.confirmPassword,
              errorText: _againError,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.actionOk)),
      ],
    );
  }
}
