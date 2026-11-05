import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/core/widgets/password_field.dart';
import 'package:huenote/features/lock/domain/master_key_service.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

enum MasterPasswordMode { setup, change, recover }

/// Create / change / reset-with-recovery-key for the master password
/// (FR-S1, S6). Pops `true` on success.
class MasterPasswordScreen extends ConsumerStatefulWidget {
  const new({required this.mode, super.key});

  final MasterPasswordMode mode;

  @override
  ConsumerState<MasterPasswordScreen> createState() =>
      _MasterPasswordScreenState();
}

class _MasterPasswordScreenState extends ConsumerState<MasterPasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _currentError;
  String? _passwordError;
  String? _confirmError;
  var _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    const min = MasterKeyService.minPasswordLength;
    setState(() {
      _currentError = null;
      _passwordError = _password.text.length < min
          ? l10n.passwordTooShort(min)
          : null;
      _confirmError = _confirm.text != _password.text
          ? l10n.passwordsDontMatch
          : null;
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _busy = true);
    final ctrl = ref.read(lockControllerProvider.notifier);
    final recovery = switch (widget.mode) {
      MasterPasswordMode.setup => await ctrl.setUp(_password.text),
      MasterPasswordMode.change => await ctrl.changePassword(
        _current.text,
        _password.text,
      ),
      MasterPasswordMode.recover => await ctrl.resetWithRecoveryKey(
        _current.text,
        _password.text,
      ),
    };
    if (!mounted) return;
    if (recovery == null) {
      setState(() {
        _busy = false;
        _currentError = widget.mode == MasterPasswordMode.recover
            ? l10n.wrongRecoveryKey
            : l10n.wrongPassword;
      });
      return;
    }
    setState(() => _busy = false);
    await showRecoveryKeyDialog(context, recovery);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (widget.mode) {
          MasterPasswordMode.setup => l10n.masterPasswordSetupTitle,
          MasterPasswordMode.change => l10n.masterPasswordChangeTitle,
          MasterPasswordMode.recover => l10n.masterPasswordRecoverTitle,
        }),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Card(
            color: scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber, color: scheme.onErrorContainer),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      l10n.masterPasswordWarning,
                      style: TextStyle(color: scheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (widget.mode == MasterPasswordMode.change) ...[
            PasswordField(
              controller: _current,
              label: l10n.currentPassword,
              errorText: _currentError,
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (widget.mode == MasterPasswordMode.recover) ...[
            TextField(
              controller: _current,
              autofocus: true,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.recoveryKey,
                hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
                errorText: _currentError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          PasswordField(
            controller: _password,
            label: widget.mode == MasterPasswordMode.setup
                ? l10n.masterPassword
                : l10n.newPassword,
            errorText: _passwordError,
            autofocus: widget.mode == MasterPasswordMode.setup,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          PasswordField(
            controller: _confirm,
            label: l10n.confirmPassword,
            errorText: _confirmError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.actionSave),
          ),
        ],
      ),
    );
  }
}

/// Shows a new recovery key once; user must confirm they saved it.
Future<void> showRecoveryKeyDialog(BuildContext context, String key) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RecoveryKeyDialog(recoveryKey: key),
  );
}

class _RecoveryKeyDialog extends StatefulWidget {
  const new({required this.recoveryKey});

  final String recoveryKey;

  @override
  State<_RecoveryKeyDialog> createState() => _RecoveryKeyDialogState();
}

class _RecoveryKeyDialogState extends State<_RecoveryKeyDialog> {
  var _saved = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.recoveryKeyTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.recoveryKeyBody),
            const SizedBox(height: AppSpacing.lg),
            SelectableText(
              widget.recoveryKey,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium!
                  .copyWith(fontFamily: 'monospace', letterSpacing: 1.2),
            ),
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(l10n.actionCopy),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: widget.recoveryKey),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.recoveryKeyCopied)));
              },
            ),
            CheckboxListTile(
              value: _saved,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.recoveryKeySaved),
              onChanged: (v) => setState(() => _saved = v ?? false),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: _saved ? () => Navigator.pop(context) : null,
            child: Text(l10n.actionOk),
          ),
        ],
      ),
    );
  }
}
