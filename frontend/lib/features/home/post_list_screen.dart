import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';
import 'models/post.dart';
import 'providers/post_provider.dart';
import 'widgets/post_card.dart';

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
  String _query = '';
  String _selectedCategory = 'All';

  static const _kCategories = [
    'All',
    'Campus',
    'International',
    'Scholarship',
    'Housing',
    'Academic',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Post> _filtered(List<Post> source) {
    var list = List<Post>.from(source);

    // category filter
    if (_selectedCategory != 'All') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }

    // text search
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where(
            (p) =>
                p.title.toLowerCase().contains(q) ||
                p.author.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final posts = _filtered(provider.posts);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            if (_isSearchOpen) _buildSearchBar(),
            _buildCategoryRow(),
            _buildSortRow(posts.length),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null
                  ? _buildError(provider)
                  : posts.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: posts.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          PostCard(post: posts[i], style: PostCardStyle.list),
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
    final onSurf = context.onSurface;
    return Container(
      color: context.cardFill,
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: onSurf,
          ),
          Expanded(
            child: Text(
              l.communityBoardTitle,
              style: GoogleFonts.notoSansKr(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: onSurf,
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
              color: onSurf,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───
  Widget _buildSearchBar() {
    return Container(
      color: context.cardFill,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: GoogleFonts.notoSansKr(fontSize: 14, color: context.onSurface),
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.communitySearchHint,
          hintStyle: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: context.hintColor,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: context.onSurfaceVar,
          ),
          filled: true,
          fillColor: context.bg,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ─── Category Filter Row ───
  Widget _buildCategoryRow() {
    return Container(
      color: context.cardFill,
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _kCategories.map((cat) {
            final selected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? context.primary : context.subtleFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : context.onSurfaceVar,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── Sort Row ───
  Widget _buildSortRow(int postCount) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: context.cardFill,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Text(
            l.communityPostCount(postCount),
            style: GoogleFonts.notoSansKr(
              fontSize: 12,
              color: context.hintColor,
            ),
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
          Icon(Icons.search_off_rounded, size: 56, color: context.hintColor),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.communityNoPosts,
            style: GoogleFonts.notoSansKr(
              fontSize: 15,
              color: context.onSurfaceVar,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(PostProvider provider) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: context.hintColor),
            const SizedBox(height: 12),
            Text(
              l.errorNetwork,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                color: context.onSurfaceVar,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.alertTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
