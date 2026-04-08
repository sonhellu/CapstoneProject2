import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import 'models/post.dart';
import 'widgets/post_card.dart';

// ─────────────────────────── Design Tokens ───────────────────────────
abstract final class _T {
  static const primary = Color(0xFF003478);
  static const background = Color(0xFFF5F7FA);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6A6A6A);
  static const textLight = Color(0xFFADB5BD);
  static const surface = Colors.white;
}

// ─────────────────────────── Screen ───────────────────────────
class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key, this.initialCategory});

  /// If provided, pre-selects the matching filter chip.
  final String? initialCategory;

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _searchCtrl = TextEditingController();
  bool _isSearchOpen = false;
  String _sortMode = 'Recent'; // 'Recent' | 'Popular'
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Post> get _filtered {
    var list = List<Post>.from(mockPosts);

    // text search
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.author.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }

    // sort
    if (_sortMode == 'Popular') {
      list.sort((a, b) => b.likes.compareTo(a.likes));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filtered;

    return Scaffold(
      backgroundColor: _T.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            if (_isSearchOpen) _buildSearchBar(),
            _buildSortRow(),
            Expanded(
              child: posts.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: posts.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => PostCard(
                            post: posts[i],
                            style: PostCardStyle.list,
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: _T.textDark,
          ),
          Expanded(
            child: Text(
              l.communityBoardTitle,
              style: GoogleFonts.notoSansKr(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _T.textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() {
              _isSearchOpen = !_isSearchOpen;
              if (!_isSearchOpen) {
                _query = '';
                _searchCtrl.clear();
              }
            }),
            icon: Icon(
              _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
              color: _T.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───
  Widget _buildSearchBar() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: GoogleFonts.notoSansKr(fontSize: 14, color: _T.textDark),
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.communitySearchHint,
          hintStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: _T.textLight,
          ),
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

  // ─── Sort Row ───
  Widget _buildSortRow() {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Text(
            l.communityPostCount(_filtered.length),
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: _T.textLight,
            ),
          ),
          const Spacer(),
          _SortChip(
            label: l.communitySortRecent,
            selected: _sortMode == 'Recent',
            onTap: () => setState(() => _sortMode = 'Recent'),
          ),
          const SizedBox(width: 8),
          _SortChip(
            label: l.communitySortPopular,
            icon: Icons.local_fire_department_rounded,
            selected: _sortMode == 'Popular',
            onTap: () => setState(() => _sortMode = 'Popular'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: _T.textLight),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.communityNoPosts,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              color: _T.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Sort Chip ───────────────────────────
class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _T.primary : const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: selected ? Colors.white : _T.textGrey),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _T.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

