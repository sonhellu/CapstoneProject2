import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';

class VisaDDayCard extends StatefulWidget {
  const VisaDDayCard({super.key});

  @override
  State<VisaDDayCard> createState() => _VisaDDayCardState();
}

class _VisaDDayCardState extends State<VisaDDayCard> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _stream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visaInfo')
          .doc('current')
          .snapshots();
    }
  }

  int _calculateDDay(DateTime expiryDate) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final expiryOnly = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );
    return expiryOnly.difference(todayOnly).inDays;
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_stream == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _EmptyVisaCard();
        }

        final data = snapshot.data!.data();
        final expiryTimestamp = data?['expiryDate'];

        if (expiryTimestamp is! Timestamp) {
          return _EmptyVisaCard();
        }

        final expiryDate = expiryTimestamp.toDate();
        final dDay = _calculateDDay(expiryDate);

        return _VisaCardContent(
          dDay: dDay,
          expiryDateText: _formatDate(expiryDate),
        );
      },
    );
  }
}

class _VisaCardContent extends StatelessWidget {
  const _VisaCardContent({
    required this.dDay,
    required this.expiryDateText,
  });

  final int dDay;
  final String expiryDateText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isExpired = dDay < 0;
    final isWarning = dDay <= 120 && dDay >= 0;

    final title = isExpired
        ? l10n.visaDDayExpired
        : isWarning
            ? l10n.visaDDayWarning
            : l10n.visaDDayUntil;

    final dDayText = isExpired ? 'D+${dDay.abs()}' : 'D-$dDay';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.withValues(alpha: 0.12)
            : isWarning
                ? Colors.orange.withValues(alpha: 0.14)
                : context.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpired
              ? Colors.red.withValues(alpha: 0.35)
              : isWarning
                  ? Colors.orange.withValues(alpha: 0.35)
                  : context.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: isExpired
                ? Colors.red
                : isWarning
                    ? Colors.orange
                    : context.primary,
            child: const Icon(
              Icons.event_available_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceVar,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dDayText,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.visaDDayExpiryLabel}$expiryDateText',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: context.onSurfaceVar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVisaCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: context.primary,
            child: const Icon(
              Icons.assignment_ind_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.visaEmptyCard,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}