import 'package:flutter/material.dart';
import 'package:huenote/app/theme/app_theme.dart';
import 'package:huenote/features/notes/domain/checklist_item.dart';
import 'package:huenote/l10n/gen/app_localizations.dart';

/// Checklist body (FR-N2). Keeps one controller/focus node per item so the
/// cursor never jumps while typing; the item list itself comes from state.
class ChecklistEditor extends StatefulWidget {
  const new({
    required this.items,
    required this.readOnly,
    required this.textStyle,
    required this.foreground,
    required this.checkedToBottom,
    required this.onChanged,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
    required this.onReorder,
    super.key,
  });

  final List<ChecklistItem> items;
  final bool readOnly;
  final TextStyle textStyle;
  final Color foreground;
  final bool checkedToBottom;
  final void Function(String id, String text) onChanged;
  final ValueChanged<String> onToggle;

  /// Returns the new item's id.
  final String Function({String? afterId}) onAdd;
  final ValueChanged<String> onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  final _controllers = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};
  String? _focusNext;
  var _showChecked = true;

  TextEditingController _controller(ChecklistItem item) => _controllers
      .putIfAbsent(item.id, () => TextEditingController(text: item.text));

  FocusNode _node(String id) => _focus.putIfAbsent(id, FocusNode.new);

  @override
  void didUpdateWidget(ChecklistEditor old) {
    super.didUpdateWidget(old);
    final ids = widget.items.map((i) => i.id).toSet();
    for (final id in _controllers.keys.toList()) {
      if (!ids.contains(id)) {
        _controllers.remove(id)!.dispose();
        _focus.remove(id)?.dispose();
      }
    }
    // External changes (e.g. convert) — sync text when not being edited.
    for (final item in widget.items) {
      final c = _controllers[item.id];
      if (c != null && c.text != item.text && !_node(item.id).hasFocus) {
        c.text = item.text;
      }
    }
    final next = _focusNext;
    if (next != null && ids.contains(next)) {
      _focusNext = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focus[next]?.requestFocus(),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _add({String? afterId}) => _focusNext = widget.onAdd(afterId: afterId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = widget.items;
    final splitChecked = widget.checkedToBottom;
    final top = splitChecked ? items.where((i) => !i.checked).toList() : items;
    final checked = splitChecked
        ? items.where((i) => i.checked).toList()
        : <ChecklistItem>[];

    return SliverMainAxisGroup(
      slivers: [
        SliverReorderableList(
          itemCount: top.length,
          // Unchecked items come first in `items`, so indexes line up.
          onReorderItem: widget.onReorder,
          itemBuilder: (context, i) => _row(top[i], index: i),
        ),
        if (!widget.readOnly)
          SliverToBoxAdapter(
            child: ListTile(
              leading: Icon(Icons.add, color: widget.foreground),
              title: Text(
                l10n.addItem,
                style: widget.textStyle.copyWith(
                  color: widget.foreground.withValues(alpha: 0.7),
                ),
              ),
              onTap: () => _add(afterId: top.isEmpty ? null : top.last.id),
            ),
          ),
        if (checked.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: ListTile(
              leading: Icon(
                _showChecked ? Icons.expand_less : Icons.expand_more,
                color: widget.foreground,
              ),
              title: Text(
                l10n.checkedItems(checked.length),
                style: TextStyle(color: widget.foreground),
              ),
              onTap: () => setState(() => _showChecked = !_showChecked),
            ),
          ),
          if (_showChecked)
            SliverList.builder(
              itemCount: checked.length,
              itemBuilder: (context, i) => _row(checked[i]),
            ),
        ],
      ],
    );
  }

  Widget _row(ChecklistItem item, {int? index}) {
    final l10n = AppLocalizations.of(context);
    final style = item.checked
        ? widget.textStyle.copyWith(
            decoration: TextDecoration.lineThrough,
            color: widget.foreground.withValues(alpha: 0.55),
          )
        : widget.textStyle;
    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          if (index != null && !widget.readOnly)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  Icons.drag_indicator,
                  color: widget.foreground.withValues(alpha: 0.5),
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          Checkbox(
            value: item.checked,
            onChanged: widget.readOnly ? null : (_) => widget.onToggle(item.id),
            side: BorderSide(color: widget.foreground, width: 1.5),
          ),
          Expanded(
            child: TextField(
              controller: _controller(item),
              focusNode: _node(item.id),
              readOnly: widget.readOnly,
              style: style,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration.collapsed(
                hintText: l10n.itemHint,
                hintStyle: style.copyWith(
                  color: widget.foreground.withValues(alpha: 0.4),
                ),
              ),
              onChanged: (t) => widget.onChanged(item.id, t),
              onSubmitted: (_) => _add(afterId: item.id),
            ),
          ),
          if (!widget.readOnly)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: Icon(
                Icons.close,
                size: 20,
                color: widget.foreground.withValues(alpha: 0.6),
              ),
              onPressed: () => widget.onRemove(item.id),
            ),
        ],
      ),
    );
  }
}
