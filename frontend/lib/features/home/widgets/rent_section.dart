import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../models/rent_item.dart';
import '../services/rent_service.dart';

class RentSection extends StatefulWidget {
  const RentSection({super.key});

  @override
  State<RentSection> createState() => _RentSectionState();
}

class _RentSectionState extends State<RentSection> {
  final _service = RentService();
  late Future<List<RentItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchRent();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RentItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 130,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError) {
          debugPrint('[RentSection] error: ${snap.error}');
          return const SizedBox.shrink();
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        final l = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  Text(
                    l.rentSectionTitle,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '달서구, 대구',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: context.onSurfaceVar,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                itemCount: items.length.clamp(0, 10),
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _RentCard(item: items[i]),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

// ── Card ────────────────────────────────────────────────────────────
class _RentCard extends StatelessWidget {
  const _RentCard({required this.item});
  final RentItem item;

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RentDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l.rentBadge,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: p,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${item.exclusiveArea}m²',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    color: context.onSurfaceVar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${l.rentDeposit} ${item.deposit}${l.rentUnit}',
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${l.rentMonthly} ${item.monthlyRent}${l.rentUnit}',
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                color: context.onSurfaceVar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Bottom Sheet ──────────────────────────────────────────────
class _RentDetailSheet extends StatelessWidget {
  const _RentDetailSheet({required this.item});
  final RentItem item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = context.primary;
    final onS = context.onSurface;

    final name = item.buildingName.isNotEmpty ? item.buildingName : l.rentBuildingUnknown;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: GoogleFonts.notoSansKr(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: onS,
              ),
            ),
            if (item.district.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.district,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  color: context.onSurfaceVar,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                _PriceChip(label: l.rentDeposit, value: '${item.deposit}${l.rentUnit}', color: p),
                const SizedBox(width: 12),
                _PriceChip(label: l.rentMonthly, value: '${item.monthlyRent}${l.rentUnit}', color: Colors.orange),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _DetailRow(icon: Icons.straighten_rounded, label: l.rentAreaLabel, value: '${item.exclusiveArea}m²'),
            _DetailRow(icon: Icons.layers_rounded, label: l.rentFloorLabel, value: '${item.floor}${l.rentFloorUnit}'),
            _DetailRow(icon: Icons.construction_rounded, label: l.rentBuildYearLabel, value: '${item.buildYear}${l.rentYearUnit}'),
            _DetailRow(icon: Icons.calendar_today_rounded, label: l.rentDealDateLabel, value: item.dealDate),
          ],
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.notoSansKr(fontSize: 11, color: color)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.notoSansKr(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.onSurfaceVar),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.notoSansKr(
                  fontSize: 13, color: context.onSurfaceVar)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface)),
        ],
      ),
    );
  }
}
