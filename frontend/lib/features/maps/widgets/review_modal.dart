import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../models/location_review.dart';
import '../repository/pin_repository.dart';

// ──────────────────────────── Entry Point ────────────────────────────

Future<void> showReviewModal(
  BuildContext context, {
  required String pinId,
  required String pinName,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewSheet(pinId: pinId, pinName: pinName),
  );
}

// ──────────────────────────── Sheet ────────────────────────────

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.pinId, required this.pinName});
  final String pinId;
  final String pinName;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _myRating = 0;
  bool _isSubmitting = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _myRating == 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await PinRepository.instance.addReview(
        pinId: widget.pinId,
        rating: _myRating,
        body: text,
      );
      if (!mounted) return;
      setState(() => _myRating = 0);
      _ctrl.clear();
      FocusScope.of(context).unfocus();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.mapPinSaveFail,
            style: GoogleFonts.notoSansKr(fontSize: 13),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _timeAgo(BuildContext context, DateTime dt) {
    final l = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return l.reviewTimeAgo(diff.inMinutes, l.reviewTimeUnitMinute);
    } else if (diff.inHours < 24) {
      return l.reviewTimeAgo(diff.inHours, l.reviewTimeUnitHour);
    } else {
      return l.reviewTimeAgo(diff.inDays, l.reviewTimeUnitDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final p = context.primary;
    final onP = context.cs.onPrimary;

    return StreamBuilder<List<LocationReview>>(
      stream: PinRepository.instance.watchReviews(widget.pinId),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? const <LocationReview>[];

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: context.cardFill,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // ── Drag handle ──
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.outline.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.reviewsTitle,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.onSurface,
                            ),
                          ),
                          Text(
                            widget.pinName,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              color: context.onSurfaceVar,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.cs.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l.reviewsCount(reviews.length),
                          style: GoogleFonts.notoSansKr(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Divider(height: 1, color: context.divider),

                // ── Review List ──
                Expanded(
                  child: reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 48,
                                color: context.outline.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l.reviewNoItems,
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 14,
                                  color: context.hintColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          itemCount: reviews.length,
                          separatorBuilder: (ctx, i) =>
                              Divider(height: 24, color: ctx.divider),
                          itemBuilder: (_, i) {
                            final r = reviews[i];
                            return _ReviewTile(
                              review: r,
                              timeAgo: _timeAgo(context, r.createdAt),
                            );
                          },
                        ),
                ),

                // ── Write Review Input ──
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Star picker
                      Row(
                        children: List.generate(5, (i) {
                          return GestureDetector(
                            onTap: () => setState(() => _myRating = i + 1),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                i < _myRating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: const Color(0xFFFFB300),
                                size: 26,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ctrl,
                              style: GoogleFonts.notoSansKr(
                                fontSize: 14,
                                color: context.onSurface,
                              ),
                              maxLines: 1,
                              decoration: InputDecoration(
                                hintText: l.reviewWriteHint,
                                hintStyle: GoogleFonts.notoSansKr(
                                  fontSize: 14,
                                  color: context.hintColor,
                                ),
                                filled: true,
                                fillColor: context.surfaceVar,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _submitReview,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: _isSubmitting
                                    ? p.withValues(alpha: 0.55)
                                    : p,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _isSubmitting ? '...' : l.reviewSubmit,
                                style: GoogleFonts.notoSansKr(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: onP,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────── Review Tile ────────────────────────────

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.timeAgo});
  final LocationReview review;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: p, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            review.authorInitial,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.cs.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + verified + time
              Row(
                children: [
                  Text(
                    '@${review.authorName}',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.onSurface,
                    ),
                  ),
                  if (review.isVerified) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded, size: 13, color: p),
                  ],
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: context.hintColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Stars
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFFFB300),
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Body
              Text(
                review.body,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: context.onSurface,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
