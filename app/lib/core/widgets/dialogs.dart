import 'package:flutter/material.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Single-choice dialog. Returns the chosen value or null.
Future<T?> chooseOne<T>(
  BuildContext context, {
  required String title,
  required List<T> values,
  required T selected,
  required String Function(T) label,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(title),
      children: [
        for (final v in values)
          ListTile(
            title: Text(label(v)),
            trailing: v == selected ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, v),
          ),
      ],
    ),
  );
}

void showSnack(BuildContext context, String message, {VoidCallback? onUndo}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: onUndo == null
            ? null
            : SnackBarAction(
                label: AppLocalizations.of(context).actionUndo,
                onPressed: onUndo,
              ),
      ),
    );
}
