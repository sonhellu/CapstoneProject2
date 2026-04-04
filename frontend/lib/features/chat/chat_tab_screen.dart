import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'chat_detail_screen.dart';
import 'models/chat_models.dart';
import 'search_partner_screen.dart';
import 'services/chat_service.dart';

// ─────────────────────────── Design Tokens ───────────────────────────
abstract final class _T {
  static const primary = Color(0xFF003478);
  static const background = Color(0xFFF5F7FA);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6A6A6A);
  static const textLight = Color(0xFFADB5BD);
  static const surface = Colors.white;
  static const divider = Color(0xFFF0F2F5);
}

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
  List<ChatModel> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    final chats = await ChatService.instance.getChatList();
    if (!mounted) return;
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  List<ChatModel> get _filtered {
    if (_query.isEmpty) return _chats;
    final q = _query.toLowerCase();
    return _chats
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
      builder: (_) => _MatchFilterSheet(
        onFind: (gender, language) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchPartnerScreen(
                gender: gender,
                language: language,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final navBarHeight = kBottomNavigationBarHeight + safeBottom;

    return Scaffold(
      backgroundColor: _T.background,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: navBarHeight - 60),
        child: FloatingActionButton(
          onPressed: _openMatchFilter,
          backgroundColor: _T.primary,
          elevation: 4,
          child: const Icon(Icons.person_search_rounded,
              color: Colors.white, size: 26),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            if (_isSearchOpen) _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildSkeleton()
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadChats,
                          color: _T.primary,
                          child: ListView.separated(
                            padding:
                                EdgeInsets.only(bottom: navBarHeight + 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              indent: 80,
                              color: _T.divider,
                            ),
                            itemBuilder: (context, i) =>
                                _ChatTile(
                              chat: _filtered[i],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    chat: _filtered[i],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Messages',
              style: GoogleFonts.notoSansKr(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _T.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: _T.textDark,
            ),
            onPressed: () => _openSearch(!_isSearchOpen),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: _T.textDark),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style:
            GoogleFonts.notoSansKr(fontSize: 14, color: _T.textDark),
        decoration: InputDecoration(
          hintText: 'Search conversations…',
          hintStyle: GoogleFonts.notoSansKr(
              fontSize: 14, color: _T.textLight),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: _T.textGrey),
          filled: true,
          fillColor: _T.background,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _T.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: _T.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No conversations yet',
            style: GoogleFonts.notoSansKr(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _T.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find a language partner to start chatting!',
            style: GoogleFonts.notoSansKr(
                fontSize: 13, color: _T.textGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openMatchFilter,
            icon: const Icon(Icons.person_search_rounded, size: 18),
            label: Text(
              'Find Partner',
              style: GoogleFonts.notoSansKr(
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _T.primary,
              foregroundColor: Colors.white,
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
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 80, color: _T.divider),
      itemBuilder: (_, _) => const _SkeletonTile(),
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
    final hasUnread = chat.unreadCount > 0;

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
                            color: _T.surface, width: 2),
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
                            color: _T.textDark,
                          ),
                        ),
                      ),
                      Text(
                        chat.lastTime,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 11,
                          color: hasUnread
                              ? _T.primary
                              : _T.textLight,
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
                          chat.isActive
                              ? chat.lastMessage
                              : '⏳ Request pending…',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 13,
                            color: hasUnread
                                ? _T.textDark
                                : _T.textGrey,
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
                          decoration: const BoxDecoration(
                            color: _T.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${chat.unreadCount > 9 ? '9+' : chat.unreadCount}',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: const Color(0xFFDDDDDD),
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
                  color: _T.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_search_rounded,
                    color: _T.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Find Language Partner',
                style: GoogleFonts.notoSansKr(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _T.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Gender
          Text(
            'Gender',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _T.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: Gender.values.map((g) {
              final label = switch (g) {
                Gender.any => '🌐  Any',
                Gender.male => '👨  Male',
                Gender.female => '👩  Female',
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
                          ? _T.primary
                          : const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? _T.primary
                            : const Color(0xFFE0E4EA),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : _T.textGrey,
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
            'Target Language to Learn',
            style: GoogleFonts.notoSansKr(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _T.textGrey,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languages.map((lang) {
              final selected = _language == lang;
              return GestureDetector(
                onTap: () => setState(() => _language = lang),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _T.primary
                        : const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? _T.primary
                          : const Color(0xFFE0E4EA),
                    ),
                  ),
                  child: Text(
                    lang,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : _T.textGrey,
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
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(
                'Find Partners',
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                foregroundColor: Colors.white,
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
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _shimmerBox(52, 52, circle: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(12, 120),
                const SizedBox(height: 6),
                _shimmerBox(10, 200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double h, double w, {bool circle = false}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(6),
      ),
    );
  }
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
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF003478),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.notoSansKr(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
