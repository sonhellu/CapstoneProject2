import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../l10n/app_localizations.dart';

// ──────────────────────────── Model ────────────────────────────

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.authorName,
    required this.authorInitial,
    required this.rating,
    required this.body,
    required this.createdAt,
    this.isVerified = false,
  });

  final String id;
  final String authorName;
  final String authorInitial;
  final int rating;
  final String body;
  final DateTime createdAt;
  final bool isVerified;
}

// ──────────────────────────── Mock data ────────────────────────────

final _mockReviews = [
  ReviewModel(
    id: 'r1',
    authorName: 'nguyen_vi',
    authorInitial: 'N',
    rating: 5,
    body: 'Quán rất ngon, phục vụ nhanh. Giá cả hợp lý cho sinh viên!',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ReviewModel(
    id: 'r2',
    authorName: 'kim_seoul',
    authorInitial: 'K',
    rating: 4,
    body: '맛있어요! 위치도 좋고 가격도 학생에게 적합해요.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isVerified: true,
  ),
  ReviewModel(
    id: 'r3',
    authorName: 'tanaka_jp',
    authorInitial: 'T',
    rating: 3,
    body: '普通です。もう少し清潔にしてほしいですね。',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

// ──────────────────────────── Entry Point ────────────────────────────

Future<void> showReviewModal(BuildContext context, {required String pinName}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReviewSheet(pinName: pinName),
  );
}

// ──────────────────────────── Sheet ────────────────────────────

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.pinName});
  final String pinName;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _myRating = 0;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: const Color(0xFFDDE3EA),
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
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        widget.pinName,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: const Color(0xFF6A6A6A),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.reviewsCount(_mockReviews.length),
                      style: GoogleFonts.notoSansKr(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF003478),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

            // ── Review List ──
            Expanded(
              child: _mockReviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.rate_review_outlined,
                              size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 12),
                          Text(
                            l.reviewNoItems,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      itemCount: _mockReviews.length,
                      separatorBuilder: (context, i) => const Divider(
                          height: 24, color: Color(0xFFF0F0F0)),
                      itemBuilder: (_, i) {
                        final r = _mockReviews[i];
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
                          style: GoogleFonts.notoSansKr(fontSize: 14),
                          maxLines: 1,
                          decoration: InputDecoration(
                            hintText: l.reviewWriteHint,
                            hintStyle: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              color: const Color(0xFFADB5BD),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          if (_ctrl.text.trim().isEmpty || _myRating == 0) {
                            return;
                          }
                          _ctrl.clear();
                          setState(() => _myRating = 0);
                          FocusScope.of(context).unfocus();
                        },
                        child: Container(
                          height: 48,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003478),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l.reviewSubmit,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
  }
}

// ──────────────────────────── Review Tile ────────────────────────────

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, required this.timeAgo});
  final ReviewModel review;
  final String timeAgo;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF003478),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            review.authorInitial,
            style: GoogleFonts.notoSansKr(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (review.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded,
                        size: 13, color: Color(0xFF003478)),
                  ],
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: const Color(0xFFADB5BD),
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
                  color: const Color(0xFF1A1A1A),
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
