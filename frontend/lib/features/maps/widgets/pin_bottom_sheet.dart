import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/geocoding_service.dart';
import '../../../l10n/app_localizations.dart';
import '../models/user_pin_model.dart';
import '../repository/pin_repository.dart';

// ──────────────────────────── Design Tokens ────────────────────────────

abstract final class _T {
  static const primary    = Color(0xFF003478);
  static const gold       = Color(0xFFFFB300);
  static const surface    = Colors.white;
  static const background = Color(0xFFF5F7FA);
  static const textDark   = Color(0xFF1A1A1A);
  static const textGrey   = Color(0xFF6A6A6A);
  static const textLight  = Color(0xFFADB5BD);
  static const border     = Color(0xFFE4E8EF);
  static const divider    = Color(0xFFF0F2F5);
  static const danger     = Color(0xFFD32F2F);
}

// ──────────────────────────── Entry Point ────────────────────────────

/// Opens a [DraggableScrollableSheet] form for pinning a location.
///
/// Pass [addressFuture] to auto-populate the address header (from
/// [GeocodingService.getLocalizedAddress]).
/// Pass [existingPin] to open in **edit mode** with pre-filled fields.
/// Returns the saved [UserPinModel] on success, or null if dismissed.
Future<UserPinModel?> showPinBottomSheet(
  BuildContext context,
  NLatLng latLng, {
  UserPinModel? existingPin,
  Future<LocalizedAddress>? addressFuture,
}) {
  return showModalBottomSheet<UserPinModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.55,
      maxChildSize: 0.93,
      expand: false,
      builder: (_, scrollCtrl) => _PinFormSheet(
        latLng: latLng,
        scrollController: scrollCtrl,
        existingPin: existingPin,
        addressFuture: addressFuture,
      ),
    ),
  );
}

// ──────────────────────────── _PinFormSheet ────────────────────────────

class _PinFormSheet extends StatefulWidget {
  const _PinFormSheet({
    required this.latLng,
    required this.scrollController,
    this.existingPin,
    this.addressFuture,
  });

  final NLatLng latLng;
  final ScrollController scrollController;
  final UserPinModel? existingPin;
  final Future<LocalizedAddress>? addressFuture;

  @override
  State<_PinFormSheet> createState() => _PinFormSheetState();
}

class _PinFormSheetState extends State<_PinFormSheet> {
  final _nameCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _nameFocus = FocusNode();

  late PinType _type;
  late bool    _isPublic;
  late int     _rating;
  bool    _isSaving = false;
  int     _photoCount = 0;

  // Resolved from addressFuture once geocoding completes
  LocalizedAddress? _resolvedAddress;

  bool get _isEditMode => widget.existingPin != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPin;
    _type     = p?.type     ?? PinType.restaurant;
    _isPublic = p?.isPublic ?? true;
    _rating   = p?.rating   ?? 5;
    if (p != null) {
      _nameCtrl.text  = p.name;
      _notesCtrl.text = p.notes;
      if (p.addressKorean.isNotEmpty) {
        _resolvedAddress = LocalizedAddress(
          korean: p.addressKorean,
          localized: p.addressLocalized,
        );
      }
    }
    // Resolve address asynchronously — update header when ready
    widget.addressFuture?.then((addr) {
      if (mounted) setState(() => _resolvedAddress = addr);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty && !_isSaving;

  Future<void> _save() async {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final existing = widget.existingPin;
    final pin = UserPinModel(
      // Preserve id + createdAt when editing so the marker key stays stable.
      id: existing?.id ?? 'pin_${DateTime.now().millisecondsSinceEpoch}',
      latLng: widget.latLng,
      name: _nameCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      type: _type,
      isPublic: _isPublic,
      rating: _rating,
      createdAt: existing?.createdAt ?? DateTime.now(),
      addressKorean: _resolvedAddress?.korean ?? '',
      addressLocalized: _resolvedAddress?.localized ?? '',
    );

    final success = await PinRepository.mockSavePin(pin);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(pin);
    } else {
      setState(() => _isSaving = false);
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.mapPinSaveFail,
            style: GoogleFonts.notoSansKr(fontSize: 13),
          ),
          backgroundColor: _T.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDE3EA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _T.gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.push_pin_rounded,
                      color: _T.gold, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? l.mapPinEditTitle : l.mapPinFormTitle,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _T.textDark,
                        ),
                      ),
                      _AddressSubtitle(resolved: _resolvedAddress, latLng: widget.latLng),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: _T.textGrey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 20, thickness: 1, color: _T.divider),
          // ── Scrollable form body ─────────────────────────────────
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                20, 4, 20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              children: [
                // ── Public / Private toggle ──────────────────────
                _SectionLabel(l.mapPinSectionVisibility),
                const SizedBox(height: 10),
                _VisibilityToggle(
                  l: l,
                  isPublic: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
                const SizedBox(height: 20),

                // ── Pin type dropdown ────────────────────────────
                _SectionLabel(l.mapPinSectionType),
                const SizedBox(height: 10),
                _TypeSelector(
                  l: l,
                  selected: _type,
                  onChanged: (t) => setState(() => _type = t),
                ),
                const SizedBox(height: 20),

                // ── Name field ───────────────────────────────────
                _SectionLabel(l.mapPinSectionName),
                const SizedBox(height: 10),
                _FormBox(
                  child: TextField(
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    maxLength: 80,
                    buildCounter: (_, {required currentLength,
                        required isFocused, maxLength}) => null,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.next,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 15, color: _T.textDark),
                    decoration: InputDecoration.collapsed(
                      hintText: l.mapPinNameHint,
                      hintStyle: GoogleFonts.notoSansKr(
                          fontSize: 15, color: _T.textLight),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Notes field ──────────────────────────────────
                _SectionLabel(l.mapPinSectionNotes),
                const SizedBox(height: 10),
                _FormBox(
                  child: TextField(
                    controller: _notesCtrl,
                    maxLines: 4,
                    maxLength: 300,
                    buildCounter: (_, {required currentLength,
                        required isFocused, maxLength}) => null,
                    style: GoogleFonts.notoSansKr(
                        fontSize: 14, color: _T.textDark, height: 1.6),
                    decoration: InputDecoration.collapsed(
                      hintText: l.mapPinNotesHint,
                      hintStyle: GoogleFonts.notoSansKr(
                          fontSize: 14, color: _T.textLight),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Rating ───────────────────────────────────────
                _SectionLabel(l.mapPinSectionRating),
                const SizedBox(height: 10),
                _StarRating(
                  rating: _rating,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = v);
                  },
                ),
                const SizedBox(height: 20),

                // ── Photo picker placeholder ─────────────────────
                _SectionLabel('${l.mapPinSectionPhotos}  ($_photoCount/4)'),
                const SizedBox(height: 10),
                _PhotoPickerRow(
                  l: l,
                  count: _photoCount,
                  onAdd: () => setState(() {
                    if (_photoCount < 4) _photoCount++;
                  }),
                  onRemove: () => setState(() {
                    if (_photoCount > 0) _photoCount--;
                  }),
                ),
                const SizedBox(height: 28),

                // ── Save button ──────────────────────────────────
                _SaveButton(
                  enabled: _canSave,
                  isSaving: _isSaving,
                  onTap: _save,
                  label: _isEditMode ? l.mapPinSaveChanges : l.mapPinSaveButton,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── _VisibilityToggle ────────────────────────────

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.l,
    required this.isPublic,
    required this.onChanged,
  });
  final AppLocalizations l;
  final bool isPublic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _T.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: Row(
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: 20,
            color: isPublic ? _T.primary : _T.textGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isPublic ? l.mapPinVisibilityPublic : l.mapPinVisibilityPrivate,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _T.textDark,
              ),
            ),
          ),
          Switch.adaptive(
            value: isPublic,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: _T.primary,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── _TypeSelector ────────────────────────────

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.l,
    required this.selected,
    required this.onChanged,
  });
  final AppLocalizations l;
  final PinType selected;
  final ValueChanged<PinType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PinType.values.map((type) {
        final isSel = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSel ? _T.gold.withValues(alpha: 0.12) : _T.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel ? _T.gold : _T.border,
                width: isSel ? 1.5 : 1,
              ),
            ),
            child: Text(
              '${type.emoji}  ${type.localizedLabel(l)}',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight:
                    isSel ? FontWeight.w700 : FontWeight.w400,
                color: isSel ? const Color(0xFF8A6000) : _T.textGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ──────────────────────────── _StarRating ────────────────────────────

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.onChanged});
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _T.gold,
              size: 34,
            ),
          ),
        );
      }),
    );
  }
}

// ──────────────────────────── _PhotoPickerRow ────────────────────────────

class _PhotoPickerRow extends StatelessWidget {
  const _PhotoPickerRow({
    required this.l,
    required this.count,
    required this.onAdd,
    required this.onRemove,
  });
  final AppLocalizations l;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (count < 4)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _T.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _T.gold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        color: _T.gold, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      l.mapPinAddPhoto,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _T.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...List.generate(count, (_) => Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _T.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _T.gold.withValues(alpha: 0.3)),
                ),
                child: Icon(Icons.image_rounded,
                    color: _T.gold.withValues(alpha: 0.5), size: 30),
              ),
              Positioned(
                top: -6,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: _T.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

// ──────────────────────────── _SaveButton ────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.isSaving,
    required this.onTap,
    required this.label,
  });
  final bool enabled;
  final bool isSaving;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _T.gold,
          disabledBackgroundColor: _T.gold.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.push_pin_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ──────────────────────────── _AddressSubtitle ────────────────────────────

class _AddressSubtitle extends StatelessWidget {
  const _AddressSubtitle({required this.resolved, required this.latLng});

  final LocalizedAddress? resolved;
  final NLatLng latLng;

  @override
  Widget build(BuildContext context) {
    // Still loading geocoding
    if (resolved == null) {
      return Row(
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: _T.textLight),
          ),
          const SizedBox(width: 6),
          Text(
            '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}',
            style: GoogleFonts.notoSansKr(fontSize: 11, color: _T.textLight),
          ),
        ],
      );
    }

    // Geocoding failed — show raw coords
    if (resolved!.localized.isEmpty) {
      return Text(
        '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}',
        style: GoogleFonts.notoSansKr(fontSize: 11, color: _T.textLight),
      );
    }

    // Show translated address + original Korean below if different
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          resolved!.localized,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _T.textGrey,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (resolved!.hasTranslation)
          Text(
            resolved!.korean,
            style: GoogleFonts.notoSansKr(fontSize: 10, color: _T.textLight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

// ──────────────────────────── Shared helpers ────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF6A6A6A),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _FormBox extends StatelessWidget {
  const _FormBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _T.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _T.border),
      ),
      child: child,
    );
  }
}
