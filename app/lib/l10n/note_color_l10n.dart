import 'package:huenote/features/notes/domain/note_color.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

/// Default (un-renamed) label for each colour. User labels come in Phase 1.
extension NoteColorL10n on NoteColor {
  String defaultLabel(AppLocalizations l10n) => switch (this) {
    NoteColor.red => l10n.colorRed,
    NoteColor.orange => l10n.colorOrange,
    NoteColor.yellow => l10n.colorYellow,
    NoteColor.green => l10n.colorGreen,
    NoteColor.blue => l10n.colorBlue,
    NoteColor.purple => l10n.colorPurple,
    NoteColor.black => l10n.colorBlack,
    NoteColor.grey => l10n.colorGrey,
    NoteColor.white => l10n.colorWhite,
  };
}
