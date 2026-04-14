import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:capstone_frontend/l10n/app_localizations.dart';
import '../../core/navigation/app_transitions.dart';
import '../../core/theme/theme_ext.dart';
import 'chat_controller.dart';
import 'chat_detail_screen.dart';
import 'models/chat_models.dart';
import 'search_partner_screen.dart';

// ─────────────────────────── Screen ───────────────────────────
class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ChatModel> _filtered(List<ChatModel> chats) {
    if (_query.isEmpty) return chats;
    final q = _query.toLowerCase();
    return chats
        .where((c) =>
            c.partner.name.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  void _openSearch(bool open) {
    setState(() {
      _isSearchOpen = open;
      if (!open) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  void _openMatchFilter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MatchFilterSheet(
        onFind: (gender, language) {
          Navigator.pop(ctx);
          Navigator.of(context).push(
            AppTransitions.fadeSlide(SearchPartnerScreen(
              gender: gender,
              language: language,
            )),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safeBottom = mq.viewPadding.bottom;
    final navBarHeight = kBottomNavigationBarHeight + safeBottom;
    final fabBottomPadding = math.max(0.0, navBarHeight + 40.0);
    final ctrl = context.watch<ChatController>();

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: context.bg,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomPadding),
        child: FloatingActionButton(
          onPressed: _openMatchFilter,
          backgroundColor: context.primary,
          elevation: 4,
          child: Icon(Icons.person_search_rounded,
              color: cs.onPrimary, size: 26),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            if (_isSearchOpen) _buildSearchBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // ── Incoming requests section ──
                  StreamBuilder<List<ChatRequestModel>>(
                    stream: ctrl.incomingRequests,
                    builder: (context, snap) {
                      final requests = snap.data ?? [];
                      if (requests.isEmpty) return const SliverToBoxAdapter();
                      return SliverToBoxAdapter(
                        child: _IncomingRequestsSection(
                          requests: requests,
                          ctrl: ctrl,
                        ),
                      );
                    },
                  ),
                  // ── Chat list ──
                  StreamBuilder<List<ChatModel>>(
                    stream: ctrl.chats,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SliverFillRemaining(child: _buildSkeleton());
                      }
                      final chats = _filtered(snapshot.data ?? []);
                      if (chats.isEmpty) {
                        return SliverFillRemaining(child: _buildEmpty());
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final chat = chats[i];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ChatTile(
                                  chat: chat,
                                  onTap: () => Navigator.of(context).push(
                                    AppTransitions.fadeSlide(
                                      ChatDetailScreen(chat: chat),
                                    ),
                                  ),
                                ),
                                if (i < chats.length - 1)
                                  Divider(
                                      height: 1,
                                      indent: 80,
                                      color: Theme.of(context).dividerColor),
                              ],
                            );
                          },
                          childCount: chats.length,
                        ),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                      child: SizedBox(height: navBarHeight + 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l = AppLocalizations.of(context)!;
    final onS = context.onSurface;
    return Container(
      color: context.cardFill,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.chatMessages,
              style: GoogleFonts.notoSansKr(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: onS,
            ),
            onPressed: () => _openSearch(!_isSearchOpen),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: onS),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: context.cardFill,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style:
            GoogleFonts.notoSansKr(fontSize: 14, color: context.onSurface),
        decoration: InputDecoration(
          hintText: l.chatSearchConversations,
          hintStyle: GoogleFonts.notoSansKr(
              fontSize: 14, color: context.hintColor),
          prefixIcon: Icon(Icons.search_rounded,
              size: 20, color: context.onSurfaceVar),
          filled: true,
          fillColor: context.bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final l = AppLocalizations.of(context)!;
    final p = context.primary;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: p.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: p.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.chatEmptyTitle,
            style: GoogleFonts.notoSansKr(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.chatEmptySubtitle,
            style: GoogleFonts.notoSansKr(
                fontSize: 13, color: context.onSurfaceVar),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openMatchFilter,
            icon: Icon(Icons.person_search_rounded, size: 18, color: cs.onPrimary),
            label: Text(
              l.chatFindPartnerButton,
              style: GoogleFonts.notoSansKr(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: p,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      key: const ValueKey('skeleton'),
      baseColor: dark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEFF1),
      highlightColor: dark ? const Color(0xFF3D3D3D) : const Color(0xFFFAFAFB),
      period: const Duration(milliseconds: 1200),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (ctx, _) =>
            Divider(height: 1, indent: 80, color: Theme.of(ctx).dividerColor),
        itemBuilder: (_, __) => const _SkeletonTile(),
      ),
    );
  }
}

// ─────────────────────────── Incoming Requests Section ───────────────────────────
class _IncomingRequestsSection extends StatelessWidget {
  const _IncomingRequestsSection({
    required this.requests,
    required this.ctrl,
  });

  final List<ChatRequestModel> requests;
  final ChatController ctrl;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: context.cardFill,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5722),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l.chatRequestsIncoming,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.onSurfaceVar,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${requests.length}',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...requests.map((req) => _RequestTile(
                request: req,
                onAccept: () => ctrl.acceptRequest(req.id),
                onDecline: () => ctrl.declineRequest(req.id),
                onAccepted: (convId) {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    AppTransitions.fadeSlide(
                      ChatDetailScreen(
                        chat: ChatModel(
                          id: convId,
                          partner: req.sender,
                          lastMessage: '',
                          lastTime: '',
                        ),
                      ),
                    ),
                  );
                },
              )),
          Divider(height: 1, color: Theme.of(context).dividerColor),
        ],
      ),
    );
  }
}

class _RequestTile extends StatefulWidget {
  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onAccepted,
  });

  final ChatRequestModel request;
  final Future<String> Function() onAccept;
  final Future<void> Function() onDecline;
  /// Called with the new [convId] after [onAccept] completes successfully.
  final void Function(String convId) onAccepted;

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _loading = false;

  Future<void> _handleAccept() async {
    setState(() => _loading = true);
    try {
      final convId = await widget.onAccept();
      if (mounted) widget.onAccepted(convId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handle(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sender = widget.request.sender;
    final p = context.primary;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _Avatar(
              initial: sender.avatarInitial, size: 44, fontSize: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sender.name,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.onSurface,
                  ),
                ),
                Text(
                  '${sender.nativeLanguage} → ${sender.learningLanguage}',
                  style: GoogleFonts.notoSansKr(
                      fontSize: 11, color: context.onSurfaceVar),
                ),
              ],
            ),
          ),
          if (_loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: p),
            )
          else ...[
            // Decline
            OutlinedButton(
              onPressed: () => _handle(widget.onDecline),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                side: BorderSide(color: context.outline.withValues(alpha: 0.5)),
                shape: const StadiumBorder(),
              ),
              child: Text(
                l.chatRequestDecline,
                style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceVar),
              ),
            ),
            const SizedBox(width: 8),
            // Accept
            ElevatedButton(
              onPressed: _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: p,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l.chatRequestAccept,
                style: GoogleFonts.notoSansKr(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── Chat Tile ───────────────────────────
class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat, required this.onTap});
  final ChatModel chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasUnread = chat.unreadCount > 0;
    final p = context.primary;
    final ring = Theme.of(context).colorScheme.surface;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar + online dot ──
            Stack(
              children: [
                _Avatar(
                  initial: chat.partner.avatarInitial,
                  size: 52,
                  fontSize: 19,
                ),
                if (chat.partner.isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
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
            const SizedBox(width: 14),
            // ── Text ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.partner.name,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: context.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        chat.lastTime,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: hasUnread
                              ? p
                              : context.hintColor,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.isDisconnected
                              ? l.chatDisconnectedListSubtitle
                              : chat.isActive
                                  ? chat.lastMessage
                                  : '⏳ ${l.chatRequestPending}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: hasUnread
                                ? context.onSurface
                                : context.onSurfaceVar,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: p,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${chat.unreadCount > 9 ? '9+' : chat.unreadCount}',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onPrimary,
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

// ─────────────────────────── Match Filter Bottom Sheet ───────────────────────────
class _MatchFilterSheet extends StatefulWidget {
  const _MatchFilterSheet({required this.onFind});
  final void Function(Gender gender, String language) onFind;

  @override
  State<_MatchFilterSheet> createState() => _MatchFilterSheetState();
}

class _MatchFilterSheetState extends State<_MatchFilterSheet> {
  Gender _gender = Gender.any;
  String _language = 'Any';

  static const _languages = [
    'Any', 'Vietnamese', 'Korean', 'English', 'Japanese', 'Chinese',
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final p = context.primary;
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, safeBottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_search_rounded,
                    color: p, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l.chatFilterFindPartner,
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gender
          Text(
            l.chatFilterGender,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.onSurfaceVar,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: Gender.values.map((g) {
              final label = switch (g) {
                Gender.any => '🌐  ${l.partnerGenderAny}',
                Gender.male => '👨  ${l.partnerGenderMale}',
                Gender.female => '👩  ${l.partnerGenderFemale}',
              };
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? p
                          : context.subtleFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? p
                            : context.outline.withValues(alpha: 0.45),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? cs.onPrimary : context.onSurfaceVar,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Language
          Text(
            l.chatFilterTargetLanguage,
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.onSurfaceVar,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages.map((lang) {
              final selected = _language == lang;
              final displayText =
                  lang == 'Any' ? l.chatFilterLanguageAny : lang;
              return GestureDetector(
                onTap: () => setState(() => _language = lang),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? p
                        : context.subtleFill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? p
                          : context.outline.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    displayText,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? cs.onPrimary : context.onSurfaceVar,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          // Find Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => widget.onFind(_gender, _language),
              icon: Icon(Icons.search_rounded, size: 18, color: cs.onPrimary),
              label: Text(
                l.chatFilterFindPartners,
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: p,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Skeleton Tile ───────────────────────────
/// Mirrors [_ChatTile] layout exactly so the shimmer transition feels natural.
/// Shimmer colour is driven by the parent [Shimmer.fromColors].
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar circle ──
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          // ── Two text lines ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row: name line + timestamp stub
                Row(
                  children: [
                    _box(h: 13, w: 130, fill: fill),
                    const Spacer(),
                    _box(h: 11, w: 36, fill: fill),
                  ],
                ),
                const SizedBox(height: 8),
                // Last message line — shorter than full width
                _box(h: 11, w: double.infinity, fill: fill),
                const SizedBox(height: 4),
                _box(h: 11, w: 140, fill: fill),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({required double h, required double w, required Color fill}) =>
      Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(6),
        ),
      );
}

// ─────────────────────────── Avatar ───────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.initial,
    this.size = 44,
    this.fontSize = 16,
  });
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
        color: cs.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.notoSansKr(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: cs.onPrimary,
        ),
      ),
    );
  }
}
