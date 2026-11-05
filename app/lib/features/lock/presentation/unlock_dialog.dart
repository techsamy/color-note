import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:huenote/app/router.dart';
import 'package:huenote/core/widgets/password_field.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

/// Asks for the master password and unlocks the session.
/// Returns true when unlocked. If no master password exists yet, opens
/// the setup screen instead.
Future<bool> ensureUnlocked(BuildContext context, WidgetRef ref) async {
  final state = await ref.read(lockControllerProvider.future);
  if (state.isUnlocked) return true;
  if (!context.mounted) return false;
  if (!state.hasMasterPassword) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.masterPasswordNeeded)));
    final created = await context.push<bool>(
      Routes.masterPassword(MasterPasswordMode.setup),
    );
    return created ?? false;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _UnlockDialog(),
  );
  return ok ?? false;
}

class _UnlockDialog extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends ConsumerState<_UnlockDialog> {
  final _password = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref
        .read(lockControllerProvider.notifier)
        .unlock(_password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = AppLocalizations.of(context).wrongPassword;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.unlockTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PasswordField(
            controller: _password,
            label: l10n.masterPassword,
            errorText: _error,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
              unawaited(
                context.push(Routes.masterPassword(MasterPasswordMode.recover)),
              );
            },
            child: Text(l10n.forgotPassword),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.actionUnlock),
        ),
      ],
    );
  }
}
