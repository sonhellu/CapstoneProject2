import 'package:flutter/material.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/register_picklist_data.dart';
import '../../theme/auth_theme.dart';

/// Opens a draggable bottom sheet with search + scrollable list of [options].
Future<String?> showSearchableOptionSheet(
  BuildContext context, {
  required String title,
  required String searchHint,
  required List<String> options,
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SearchableOptionSheet(
      title: title,
      searchHint: searchHint,
      options: options,
      selected: selected,
    ),
  );
}

class _SearchableOptionSheet extends StatefulWidget {
  const _SearchableOptionSheet({
    required this.title,
    required this.searchHint,
    required this.options,
    required this.selected,
  });

  final String title;
  final String searchHint;
  final List<String> options;
  final String? selected;

  @override
  State<_SearchableOptionSheet> createState() => _SearchableOptionSheetState();
}

class _SearchableOptionSheetState extends State<_SearchableOptionSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final filtered = filterOptions(widget.options, _query);
    final p = context.primary;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.45,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: p),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        l.alertNotFound,
                        style: TextStyle(color: context.onSurfaceVar),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final opt = filtered[i];
                        final isSel = opt == widget.selected;
                        return ListTile(
                          dense: true,
                          title: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? p : context.onSurface,
                            ),
                          ),
                          trailing: isSel
                              ? Icon(Icons.check_rounded, color: p, size: 20)
                              : null,
                          onTap: () => Navigator.pop(context, opt),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable row styled like other auth fields; opens [showSearchableOptionSheet].
class RegisterSearchableField extends StatelessWidget {
  const RegisterSearchableField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.errorText,
    this.leadingIcon = Icons.arrow_drop_down_circle_outlined,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final String? errorText;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    final hasValue = value != null && value!.isNotEmpty;
    final err = errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: context.subtleFill,
              border: Border.all(
                color: err != null
                    ? Theme.of(context).colorScheme.error
                    : context.outline.withValues(alpha: 0.9),
              ),
              borderRadius: BorderRadius.circular(AuthRadii.sm),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  leadingIcon,
                  size: 20,
                  color: p,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? value! : placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? context.onSurface
                          : context.onSurfaceVar.withValues(alpha: 0.75),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.expand_more_rounded,
                    size: 20, color: context.onSurfaceVar),
              ],
            ),
          ),
        ),
        if (err != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              err,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
