import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/errors/send_chat_request_result.dart';
import '../../core/navigation/app_transitions.dart';
import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';
import 'chat_detail_screen.dart';
import 'models/chat_models.dart';
import 'services/chat_service.dart';

// ─────────────────────────── Language Config ───────────────────────────
const _langColors = <String, Color>{
  'Vietnamese': Color(0xFFD32F2F),
  'Korean': Color(0xFF2563EB),
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

  /// Active Firestore listeners keyed by partner ID.
  /// Each fires when the partner accepts (status → 'active').
  final _subs = <String, StreamSubscription<DocumentSnapshot>>{};

  @override
  void initState() {
    super.initState();
    _resultsFuture = ChatService.instance.searchPartners(
      gender: widget.gender,
      language: widget.language,
    );
    _resultsFuture.then((partners) {
      if (mounted) _initStatuses(partners);
    });
  }

  /// Batch-reads chat_requests for every search result and seeds button states.
  /// Also starts watchers for any pending outgoing requests (so accept is detected live).
  Future<void> _initStatuses(List<PartnerModel> partners) async {
    if (partners.isEmpty) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final snaps = await Future.wait(
      partners.map((p) => FirebaseFirestore.instance
          .collection('chat_requests')
          .doc(_requestId(p.id))
          .get()),
    );

    if (!mounted) return;
    final updates = <String, RequestStatus>{};
    for (var i = 0; i < partners.length; i++) {
      final data = snaps[i].data();
      if (data == null) continue;
      final status = data['status'] as String?;
      final senderId = data['senderId'] as String?;
      if (status == 'active') {
        updates[partners[i].id] = RequestStatus.accepted;
      } else if (status == 'pending' && senderId == myUid) {
        updates[partners[i].id] = RequestStatus.pending;
        _watchRequest(partners[i]); // detect when partner accepts
      }
    }
    if (updates.isNotEmpty) setState(() => _requestStatuses.addAll(updates));
  }

  @override
  void dispose() {
    for (final s in _subs.values) { s.cancel(); }
    super.dispose();
  }

  String _requestId(String partnerId) {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return myUid.compareTo(partnerId) <= 0
        ? '${myUid}_$partnerId'
        : '${partnerId}_$myUid';
  }

  void _watchRequest(PartnerModel partner) {
    _subs[partner.id]?.cancel();
    _subs[partner.id] = FirebaseFirestore.instance
        .collection('chat_requests')
        .doc(_requestId(partner.id))
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final status = snap.data()?['status'] as String?;
      if (status == 'active') {
        setState(
            () => _requestStatuses[partner.id] = RequestStatus.accepted);
        _subs.remove(partner.id)?.cancel();
      } else if (snap.data() == null) {
        // Doc deleted (declined) — reset button.
        setState(() => _requestStatuses.remove(partner.id));
        _subs.remove(partner.id)?.cancel();
      }
    });
  }

  void _openChat(PartnerModel partner) {
    final chat = ChatModel(
      id: _requestId(partner.id),
      partner: partner,
      lastMessage: '',
      lastTime: '',
      status: ChatSyncStatus.active,
    );
    Navigator.of(context).push(
      AppTransitions.fadeSlide(ChatDetailScreen(chat: chat)),
    );
  }

  Future<void> _sendRequest(PartnerModel partner) async {
    setState(() => _requestStatuses[partner.id] = RequestStatus.pending);
    final result = await ChatService.instance.sendRequest(partner.id);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (result == SendChatRequestResult.sent) {
      _watchRequest(partner); // start listening for accept
    } else {
      setState(() => _requestStatuses.remove(partner.id));
    }

    final text = switch (result) {
      SendChatRequestResult.sent => l.partnerRequestSentSuccess,
      SendChatRequestResult.notSignedIn => l.partnerRequestNotSignedIn,
      SendChatRequestResult.partnerProfileMissing =>
        l.partnerRequestProfileMissing,
      SendChatRequestResult.alreadyPending =>
        l.partnerRequestAlreadyPending,
      SendChatRequestResult.incomingPendingExists =>
        l.partnerRequestIncomingPending,
      SendChatRequestResult.alreadyAccepted =>
        l.partnerRequestAlreadyAccepted,
      SendChatRequestResult.failed => l.partnerRequestFailed,
    };
    messenger.showSnackBar(
      SnackBar(
        content: Text(text, style: GoogleFonts.notoSansKr(fontSize: 14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final genderLabel = switch (widget.gender) {
      Gender.any => l.partnerGenderAny,
      Gender.male => l.partnerGenderMale,
      Gender.female => l.partnerGenderFemale,
    };

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, l, genderLabel),
            Expanded(
              child: FutureBuilder<List<PartnerModel>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoading();
                  }
                  final partners = snapshot.data ?? [];
                  if (partners.isEmpty) return _buildEmpty(context);
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: partners.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PartnerCard(
                      partner: partners[i],
                      status: _requestStatuses[partners[i].id] ??
                          RequestStatus.none,
                      onSendRequest: () => _sendRequest(partners[i]),
                      onOpenChat: () => _openChat(partners[i]),
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

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l,
    String genderLabel,
  ) {
    return Container(
      color: context.cardFill,
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: context.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.partnerSearchTitle,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
                  ),
                ),
                Text(
                  '$genderLabel · ${widget.language}',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 12, color: context.onSurfaceVar),
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

  Widget _buildEmpty(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64,
              color: context.primary.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text(
            l.partnerEmptyTitle,
            style: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.partnerEmptySubtitle,
            style: GoogleFonts.notoSansKr(
                fontSize: 13, color: context.onSurfaceVar),
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
    required this.onOpenChat,
  });

  final PartnerModel partner;
  final RequestStatus status;
  final VoidCallback onSendRequest;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = context.primary;
    final nativeFg =
        _langColors[partner.nativeLanguage] ?? p;
    final nativeBg =
        _langBg[partner.nativeLanguage] ?? context.subtleFill;
    final learnFg =
        _langColors[partner.learningLanguage] ?? p;
    final learnBg =
        _langBg[partner.learningLanguage] ?? context.subtleFill;
    final ring = Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardElevationShadow,
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
                              color: ring, width: 2),
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
                        color: context.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      partner.school,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: context.onSurfaceVar),
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
                    l.partnerOnline,
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
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: context.hintColor),
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
              color: context.onSurfaceVar,
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
              l: l,
              status: status,
              onTap: onSendRequest,
              onOpenChat: onOpenChat,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Request Button ───────────────────────────
class _RequestButton extends StatelessWidget {
  const _RequestButton({
    required this.l,
    required this.status,
    required this.onTap,
    required this.onOpenChat,
  });
  final AppLocalizations l;
  final RequestStatus status;
  final VoidCallback onTap;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      RequestStatus.none => ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(Icons.send_rounded, size: 16, color: cs.onPrimary),
          label: Text(
            l.partnerSendRequest,
            style: GoogleFonts.notoSansKr(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: p,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
        ),
      RequestStatus.pending => OutlinedButton.icon(
          onPressed: null,
          icon: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(context.hintColor),
            ),
          ),
          label: Text(
            l.partnerPending,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.hintColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: const StadiumBorder(),
            side: BorderSide(color: context.outline.withValues(alpha: 0.5)),
          ),
        ),
      RequestStatus.accepted => ElevatedButton.icon(
          onPressed: onOpenChat,
          icon: const Icon(Icons.chat_bubble_rounded, size: 16),
          label: Text(
            l.partnerOpenChat,
            style: GoogleFonts.notoSans(
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
    final fill =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _box(50, 50, circle: true, fill: fill),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(14, 120, fill: fill),
                  const SizedBox(height: 6),
                  _box(10, 160, fill: fill),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _box(10, 200, fill: fill),
          const SizedBox(height: 8),
          _box(10, double.infinity, fill: fill),
          const SizedBox(height: 8),
          _box(10, 240, fill: fill),
        ],
      ),
    );
  }

  Widget _box(double h, double w,
      {bool circle = false, required Color fill}) =>
      Container(
        width: w,
        height: h,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: fill,
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: cs.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.notoSansKr(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: cs.onPrimary),
      ),
    );
  }
}
