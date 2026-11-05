import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/core/network/api_client.dart';
import 'package:huenote/core/widgets/dialogs.dart';
import 'package:huenote/core/widgets/password_field.dart';
import 'package:huenote/features/auth/auth_providers.dart';
import 'package:huenote/features/auth/domain/account.dart';
import 'package:huenote/features/lock/presentation/unlock_dialog.dart';
import 'package:huenote/features/sync/sync_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';
import 'package:intl/intl.dart';

/// FR-B2..B6, B10 — optional account, sync status, sign out, delete.
class AccountScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final account = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: account.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (a) => a == null ? const _SignInForm() : _SignedIn(account: a),
      ),
    );
  }
}

String apiErrorText(AppLocalizations l10n, Object e) {
  if (e is ApiException) {
    return e.isNetwork ? l10n.networkError : (e.firstFieldError() ?? e.message);
  }
  return '$e';
}

class _SignInForm extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  var _create = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_email.text.contains('@')) {
      setState(() => _error = l10n.invalidEmail);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (_create) {
        await auth.signUp(
          _email.text,
          _password.text,
          name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        );
      } else {
        await auth.signIn(_email.text, _password.text);
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = apiErrorText(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final l10n = AppLocalizations.of(context);
    if (!_email.text.contains('@')) {
      setState(() => _error = l10n.invalidEmail);
      return;
    }
    try {
      await ref.read(authApiProvider).forgotPassword(_email.text.trim());
      if (mounted) showSnack(context, l10n.resetEmailSent);
    } on Object catch (e) {
      if (mounted) setState(() => _error = apiErrorText(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.accountIntro),
        const SizedBox(height: AppSpacing.xl),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l10n.accountSignInTab)),
            ButtonSegment(value: true, label: Text(l10n.accountCreateTab)),
          ],
          selected: {_create},
          onSelectionChanged: (s) => setState(() {
            _create = s.first;
            _error = null;
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_create) ...[
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.nameOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            labelText: l10n.email,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PasswordField(
          controller: _password,
          label: l10n.password,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_create ? l10n.accountCreate : l10n.accountSignIn),
        ),
        if (!_create)
          TextButton(
            onPressed: _forgot,
            child: Text(l10n.forgotAccountPassword),
          ),
      ],
    );
  }
}

class _SignedIn extends ConsumerWidget {
  const new({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final status = ref.watch(syncControllerProvider);
    final sync = ref.read(syncControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final last = status.lastSyncedAt;
    final locale = Localizations.localeOf(context).toString();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(account.name ?? l10n.signedInAs(account.email)),
          subtitle: account.name == null ? null : Text(account.email),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: ListTile(
            leading: status.syncing
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    status.error == null ? Icons.cloud_done : Icons.cloud_off,
                    color: status.error == null ? null : scheme.error,
                  ),
            title: Text(
              status.syncing
                  ? l10n.syncing
                  : last == null
                  ? l10n.neverSynced
                  : l10n.lastSynced(
                      DateFormat.jm(locale).format(last.toLocal()),
                    ),
            ),
            subtitle: status.error == null
                ? null
                : Text(l10n.syncFailed(apiErrorText(l10n, status.error!))),
            trailing: TextButton(
              onPressed: status.syncing ? null : sync.syncNow,
              child: Text(l10n.syncNow),
            ),
          ),
        ),
        if (status.keyMismatch) ...[
          const SizedBox(height: AppSpacing.md),
          Card(
            color: scheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.keyMismatchTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.keyMismatchBody),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.tonal(
                    onPressed: () => _resolveKeys(context, ref),
                    child: Text(l10n.keyMismatchAction),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: Text(l10n.signOut),
          onPressed: () => _signOut(context, ref),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => _delete(context, ref),
          child: Text(l10n.deleteAccount),
        ),
      ],
    );
  }

  Future<void> _resolveKeys(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // This device's locked notes must be readable before re-encrypting.
    if (!await ensureUnlocked(context, ref) || !context.mounted) return;
    final password = await _askPassword(context, l10n.accountMasterPassword);
    if (password == null || !context.mounted) return;
    final ok = await ref
        .read(syncControllerProvider.notifier)
        .resolveKeyMismatch(password);
    if (context.mounted) {
      showSnack(context, ok ? l10n.keyMismatchResolved : l10n.wrongPassword);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final keep = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(l10n.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.signOutKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.signOutRemove),
          ),
        ],
      ),
    );
    if (keep == null) return;
    await ref.read(authControllerProvider.notifier).signOut(keepNotes: keep);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirm(
      context,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountBody,
      confirmLabel: l10n.deleteAccountConfirm,
    );
    if (!ok || !context.mounted) return;
    final password = await _askPassword(context, l10n.password);
    if (password == null || !context.mounted) return;
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(password);
      if (context.mounted) showSnack(context, l10n.accountDeleted);
    } on Object catch (e) {
      if (context.mounted) showSnack(context, apiErrorText(l10n, e));
    }
  }

  Future<String?> _askPassword(BuildContext context, String label) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        content: PasswordField(
          controller: controller,
          label: label,
          autofocus: true,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.actionOk),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
