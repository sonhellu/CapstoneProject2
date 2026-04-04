import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/chat_models.dart';
import 'services/chat_service.dart';

// ─────────────────────────── Design Tokens ───────────────────────────
abstract final class _T {
  static const primary = Color(0xFF003478);
  static const background = Color(0xFFF5F7FA);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6A6A6A);
  static const textLight = Color(0xFFADB5BD);
  static const surface = Colors.white;
}

// ─────────────────────────── Language Config ───────────────────────────
const _langColors = <String, Color>{
  'Vietnamese': Color(0xFFD32F2F),
  'Korean': Color(0xFF003478),
  'English': Color(0xFF2E7D32),
  'Japanese': Color(0xFFE65100),
  'Chinese': Color(0xFFC62828),
  'Myanmar': Color(0xFF6A1B9A),
};

const _langBg = <String, Color>{
  'Vietnamese': Color(0xFFFFECEC),
  'Korean': Color(0xFFE8F0FE),
  'English': Color(0xFFE8F5E9),
  'Japanese': Color(0xFFFFF3E0),
  'Chinese': Color(0xFFFFEBEE),
  'Myanmar': Color(0xFFF3E5F5),
};

// ─────────────────────────── Screen ───────────────────────────
class SearchPartnerScreen extends StatefulWidget {
  const SearchPartnerScreen({
    super.key,
    required this.gender,
    required this.language,
  });

  final Gender gender;
  final String language;

  @override
  State<SearchPartnerScreen> createState() => _SearchPartnerScreenState();
}

class _SearchPartnerScreenState extends State<SearchPartnerScreen> {
  late Future<List<PartnerModel>> _resultsFuture;
  final _requestStatuses = <String, RequestStatus>{};

  @override
  void initState() {
    super.initState();
    _resultsFuture = ChatService.instance.searchPartners(
      gender: widget.gender,
      language: widget.language,
    );
  }

  Future<void> _sendRequest(PartnerModel partner) async {
    setState(() =>
        _requestStatuses[partner.id] = RequestStatus.pending);
    await ChatService.instance.sendRequest(partner.id);
    if (!mounted) return;
    // In production: backend sends push notification to partner
    // For now stay as pending until partner accepts
  }

  @override
  Widget build(BuildContext context) {
    final genderLabel = switch (widget.gender) {
      Gender.any => 'Any',
      Gender.male => 'Male',
      Gender.female => 'Female',
    };

    return Scaffold(
      backgroundColor: _T.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, genderLabel),
            Expanded(
              child: FutureBuilder<List<PartnerModel>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  }
                  final partners = snapshot.data ?? [];
                  if (partners.isEmpty) return _buildEmpty();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: partners.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PartnerCard(
                      partner: partners[i],
                      status: _requestStatuses[partners[i].id] ??
                          RequestStatus.none,
                      onSendRequest: () => _sendRequest(partners[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String genderLabel) {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _T.textDark,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language Partners',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _T.textDark,
                  ),
                ),
                Text(
                  '$genderLabel · ${widget.language}',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 12, color: _T.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      itemCount: 4,
      separatorBuilder: (_, i) => const SizedBox(height: 12),
      itemBuilder: (_, i) => const _SkeletonCard(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64,
              color: _T.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            'No partners found',
            style: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _T.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your filter settings.',
            style: GoogleFonts.notoSansKr(
                fontSize: 13, color: _T.textGrey),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Partner Card ───────────────────────────
class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.partner,
    required this.status,
    required this.onSendRequest,
  });

  final PartnerModel partner;
  final RequestStatus status;
  final VoidCallback onSendRequest;

  @override
  Widget build(BuildContext context) {
    final nativeFg =
        _langColors[partner.nativeLanguage] ?? _T.primary;
    final nativeBg =
        _langBg[partner.nativeLanguage] ?? const Color(0xFFF0F0F0);
    final learnFg =
        _langColors[partner.learningLanguage] ?? _T.primary;
    final learnBg =
        _langBg[partner.learningLanguage] ?? const Color(0xFFF0F0F0);

    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ──
          Row(
            children: [
              // Avatar + online
              Stack(
                children: [
                  _Avatar(
                    initial: partner.avatarInitial,
                    size: 50,
                    fontSize: 18,
                  ),
                  if (partner.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _T.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partner.school,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: _T.textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Online badge
              if (partner.isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Online',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // ── Language pills ──
          Row(
            children: [
              _LangPill(
                  label: '🗣 ${partner.nativeLanguage}',
                  bg: nativeBg,
                  fg: nativeFg),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: _T.textLight),
              const SizedBox(width: 6),
              _LangPill(
                  label: '📖 ${partner.learningLanguage}',
                  bg: learnBg,
                  fg: learnFg),
            ],
          ),
          const SizedBox(height: 10),
          // ── Bio ──
          Text(
            partner.bio,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              color: _T.textGrey,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          // ── Request Button ──
          SizedBox(
            width: double.infinity,
            child: _RequestButton(
                status: status, onTap: onSendRequest),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Request Button ───────────────────────────
class _RequestButton extends StatelessWidget {
  const _RequestButton({required this.status, required this.onTap});
  final RequestStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      RequestStatus.none => ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: Text(
            'Send Request',
            style: GoogleFonts.notoSansKr(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _T.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      RequestStatus.pending => OutlinedButton.icon(
          onPressed: null,
          icon: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFFADB5BD)),
            ),
          ),
          label: Text(
            'Pending…',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _T.textLight,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: const StadiumBorder(),
            side: const BorderSide(color: Color(0xFFDDE3EA)),
          ),
        ),
      RequestStatus.accepted => ElevatedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: Text(
            'Accepted!',
            style: GoogleFonts.notoSansKr(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      RequestStatus.rejected => const SizedBox.shrink(),
    };
  }
}

// ─────────────────────────── Skeleton Card ───────────────────────────
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(50, 50, circle: true),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(14, 120),
                  const SizedBox(height: 6),
                  _box(10, 160),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _box(10, 200),
          const SizedBox(height: 8),
          _box(10, double.infinity),
          const SizedBox(height: 8),
          _box(10, 240),
        ],
      ),
    );
  }

  Widget _box(double h, double w, {bool circle = false}) => Container(
        width: w,
        height: h,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(6),
        ),
      );
}

// ─────────────────────────── Shared widgets ───────────────────────────
class _LangPill extends StatelessWidget {
  const _LangPill(
      {required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(
      {required this.initial, this.size = 44, this.fontSize = 16});
  final String initial;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          color: Color(0xFF003478), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.notoSansKr(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white),
      ),
    );
  }
}
