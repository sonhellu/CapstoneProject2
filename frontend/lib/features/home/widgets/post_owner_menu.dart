import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';

// ─────────────────────────── Public widget ───────────────────────────

/// Three-dot menu that appears only when [currentUserId] matches
/// [post.userId].  Provides Edit and Delete actions.
///
/// [onDeleted] is called after the post is successfully removed so
/// the caller (e.g. PostDetailScreen) can pop itself.
class PostOwnerMenu extends StatelessWidget {
  const PostOwnerMenu({
    super.key,
    required this.post,
    required this.currentUserId,
    this.iconColor,
    this.onDeleted,
  });

  final Post post;
  final String currentUserId;

  /// Override icon color (useful on dark app-bar backgrounds).
  final Color? iconColor;

  /// Called after deletion succeeds — use this to pop a detail screen.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    // ── Ownership check: hide entirely if not the author ──
    if (post.userId.isEmpty || post.userId != currentUserId) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final color = iconColor ?? cs.onSurface;

    return PopupMenuButton<_MenuAction>(
      icon: Icon(Icons.more_vert_rounded, color: color, size: 22),
      color: cs.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case _MenuAction.edit:
            _showEditSheet(context);
          case _MenuAction.delete:
            _showDeleteDialog(context);
        }
      },
      itemBuilder: (_) => [
        _menuItem(
          value: _MenuAction.edit,
          icon: Icons.edit_outlined,
          label: l.postMenuEdit,
          color: cs.onSurface,
        ),
        _menuItem(
          value: _MenuAction.delete,
          icon: Icons.delete_outline_rounded,
          label: l.postMenuDelete,
          color: Colors.red,
        ),
      ],
    );
  }

  PopupMenuItem<_MenuAction> _menuItem({
    required _MenuAction value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<_MenuAction>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Edit ─────────────────────────────────────────────────────────
  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPostSheet(
        post: post,
        // Pass the provider via the outer context while the sheet is open
        postProvider: context.read<PostProvider>(),
      ),
    );
  }

  // ─── Delete ───────────────────────────────────────────────────────
  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        post: post,
        postProvider: context.read<PostProvider>(),
        onDeleted: onDeleted,
      ),
    );
  }
}

// ─────────────────────────── Enum ────────────────────────────────────
enum _MenuAction { edit, delete }

// ─────────────────────────── Edit Sheet ──────────────────────────────
class _EditPostSheet extends StatefulWidget {
  const _EditPostSheet({required this.post, required this.postProvider});
  final Post post;
  final PostProvider postProvider;

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl   = TextEditingController(text: widget.post.title);
    _contentCtrl = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _titleCtrl.text.trim() != widget.post.title ||
      _contentCtrl.text.trim() != widget.post.content;

  Future<void> _save() async {
    final title   = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty || !_hasChanges) return;

    setState(() => _isSaving = true);
    try {
      await widget.postProvider.updatePost(
        widget.post.id,
        title: title,
        content: content,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack(context, AppLocalizations.of(context)!.postUpdateSuccess);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l  = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ──
          Text(
            l.postEditSheetTitle,
            style: GoogleFonts.notoSansKr(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 18),

          // ── Title field ──
          _SheetField(
            controller: _titleCtrl,
            label: l.postEditTitleLabel,
            maxLines: 2,
            maxLength: 200,
          ),
          const SizedBox(height: 14),

          // ── Content field ──
          _SheetField(
            controller: _contentCtrl,
            label: l.postEditContentLabel,
            maxLines: 6,
            maxLength: 2000,
          ),
          const SizedBox(height: 20),

          // ── Update button ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ListenableBuilder(
              listenable: Listenable.merge([_titleCtrl, _contentCtrl]),
              builder: (_, _) {
                final canSave = !_isSaving && _hasChanges &&
                    _titleCtrl.text.trim().isNotEmpty &&
                    _contentCtrl.text.trim().isNotEmpty;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canSave ? cs.primary : cs.surfaceContainerHighest,
                    foregroundColor:
                        canSave ? cs.onPrimary : cs.onSurfaceVariant,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canSave ? _save : null,
                  child: _isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : Text(
                          l.postEditUpdateBtn,
                          style: GoogleFonts.notoSansKr(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Delete Dialog ───────────────────────────
class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({
    required this.post,
    required this.postProvider,
    this.onDeleted,
  });
  final Post post;
  final PostProvider postProvider;
  final VoidCallback? onDeleted;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _isDeleting = false;

  Future<void> _confirm() async {
    setState(() => _isDeleting = true);
    try {
      await widget.postProvider.deletePost(widget.post.id);
      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog
      widget.onDeleted?.call();
      _showSnack(
        context,
        AppLocalizations.of(context)!.postDeleteSuccess,
        isDestructive: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l  = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l.postDeleteTitle,
        style: GoogleFonts.notoSansKr(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          color: cs.onSurface,
        ),
      ),
      content: Text(
        l.postDeleteMessage,
        style: GoogleFonts.notoSansKr(
          fontSize: 14,
          color: cs.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      actions: [
        // Cancel
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: Text(
            l.postDeleteCancel,
            style: GoogleFonts.notoSansKr(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        // Delete
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isDeleting ? null : _confirm,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l.postDeleteConfirm,
                  style: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Shared helpers ──────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    required this.maxLines,
    required this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.notoSansKr(fontSize: 14, color: cs.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.notoSansKr(
          fontSize: 13,
          color: cs.onSurfaceVariant,
        ),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

/// Shows a SnackBar from any context.  Safe to call after async gaps
/// because it uses the [ScaffoldMessenger] which outlives the widget.
void _showSnack(
  BuildContext context,
  String message, {
  bool isDestructive = false,
}) {
  final cs = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.notoSansKr(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.white : cs.onInverseSurface,
        ),
      ),
      backgroundColor:
          isDestructive ? Colors.red.shade700 : cs.inverseSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ),
  );
}
