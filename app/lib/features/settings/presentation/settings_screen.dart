import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:huenote/app/config/app_config.dart';
import 'package:huenote/app/router.dart';
import 'package:huenote/app/theme/note_palette.dart';
import 'package:huenote/core/widgets/dialogs.dart';
import 'package:huenote/features/lock/lock_providers.dart';
import 'package:huenote/features/notes/notes_providers.dart';
import 'package:huenote/features/notes/presentation/color_picker_sheet.dart';
import 'package:huenote/features/settings/domain/app_settings.dart';
import 'package:huenote/features/settings/settings_providers.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';
import 'package:huenote/l10n/note_color_l10n.dart';

/// FR-W2.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final lock = ref.watch(lockControllerProvider).value;
    final labels = ref.watch(colorLabelsProvider).value ?? const {};

    String themeLabel(AppThemeMode m) => switch (m) {
      AppThemeMode.system => l10n.themeSystem,
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
    };
    String fontLabel(NoteFontSize f) => switch (f) {
      NoteFontSize.small => l10n.fontSmall,
      NoteFontSize.medium => l10n.fontMedium,
      NoteFontSize.large => l10n.fontLarge,
      NoteFontSize.extraLarge => l10n.fontExtraLarge,
    };
    String retentionLabel(int d) =>
        d == 0 ? l10n.retentionNever : l10n.retentionDays(d);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _Header(l10n.settingsAppearance),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.settingsTheme),
            subtitle: Text(themeLabel(s.themeMode)),
            onTap: () async {
              final v = await chooseOne(
                context,
                title: l10n.settingsTheme,
                values: AppThemeMode.values,
                selected: s.themeMode,
                label: themeLabel,
              );
              if (v != null) await ctrl.update((x) => x.copyWith(themeMode: v));
            },
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(l10n.settingsFontSize),
            subtitle: Text(fontLabel(s.fontSize)),
            onTap: () async {
              final v = await chooseOne(
                context,
                title: l10n.settingsFontSize,
                values: NoteFontSize.values,
                selected: s.fontSize,
                label: fontLabel,
              );
              if (v != null) await ctrl.update((x) => x.copyWith(fontSize: v));
            },
          ),
          ListTile(
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: NotePalette.of(
                context,
              )[s.defaultColor].background,
            ),
            title: Text(l10n.settingsDefaultColor),
            subtitle: Text(s.defaultColor.label(l10n, labels)),
            onTap: () async {
              final c = await pickNoteColor(context, selected: s.defaultColor);
              if (c != null) {
                await ctrl.update((x) => x.copyWith(defaultColor: c));
              }
            },
          ),
          _Header(l10n.settingsNotes),
          SwitchListTile(
            secondary: const Icon(Icons.checklist),
            title: Text(l10n.settingsCheckedToBottom),
            value: s.checkedToBottom,
            onChanged: (v) =>
                ctrl.update((x) => x.copyWith(checkedToBottom: v)),
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete_outlined),
            title: Text(l10n.settingsTrashRetention),
            subtitle: Text(retentionLabel(s.trashRetentionDays)),
            onTap: () async {
              final v = await chooseOne(
                context,
                title: l10n.settingsTrashRetention,
                values: const [7, 30, 90, 0],
                selected: s.trashRetentionDays,
                label: retentionLabel,
              );
              if (v != null) {
                await ctrl.update((x) => x.copyWith(trashRetentionDays: v));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l10n.settingsColorLabels),
            subtitle: Text(l10n.settingsColorLabelsHint),
            onTap: () => context.push(Routes.colorLabels),
          ),
          _Header(l10n.settingsSecurity),
          if (lock == null || !lock.hasMasterPassword)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.settingsMasterPasswordSet),
              subtitle: Text(l10n.settingsMasterPasswordSetHint),
              onTap: () =>
                  context.push(Routes.masterPassword(MasterPasswordMode.setup)),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.password),
              title: Text(l10n.settingsMasterPasswordChange),
              onTap: () => context.push(
                Routes.masterPassword(MasterPasswordMode.change),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: Text(l10n.settingsMasterPasswordForgot),
              onTap: () => context.push(
                Routes.masterPassword(MasterPasswordMode.recover),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.settingsAutoLock),
              subtitle: Text(l10n.minutes(s.autoRelockMinutes)),
              onTap: () async {
                final v = await chooseOne(
                  context,
                  title: l10n.settingsAutoLock,
                  values: const [1, 5, 15, 30],
                  selected: s.autoRelockMinutes,
                  label: l10n.minutes,
                );
                if (v != null) {
                  await ctrl.update((x) => x.copyWith(autoRelockMinutes: v));
                }
              },
            ),
            if (lock.isUnlocked)
              ListTile(
                leading: const Icon(Icons.lock),
                title: Text(l10n.settingsLockNow),
                onTap: () {
                  ref.read(lockControllerProvider.notifier).lock();
                  showSnack(context, l10n.notesLocked);
                },
              ),
          ],
          _Header(l10n.settingsBackup),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(l10n.settingsBackup),
            subtitle: Text(l10n.settingsBackupHint),
            onTap: () => context.push(Routes.backup),
          ),
          _Header(l10n.settingsAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appTitle),
            subtitle: Text(l10n.settingsVersion(AppConfig.appVersion)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge!
          .copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
