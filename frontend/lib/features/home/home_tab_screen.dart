import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/navigation/app_transitions.dart';
import '../../core/widgets/language_picker_button.dart';
import '../../l10n/app_localizations.dart';
import 'create_post_screen.dart';
import 'models/post.dart';
import 'post_list_screen.dart';
import 'widgets/post_card.dart';

// ─────────────────────────── Design Tokens ───────────────────────────
abstract final class _T {
  static const primary = Color(0xFF003478);
  static const background = Color(0xFFF5F7FA);
  static const textGrey = Color(0xFF6A6A6A);
  static const radius = 16.0;
}

// ─────────────────────────── Banner Data ───────────────────────────
class _BannerItem {
  final String imageUrl;
  final String caption;
  const _BannerItem(this.imageUrl, this.caption);
}

const _banners = [
  _BannerItem(
    'https://images.unsplash.com/photo-1541410965313-d53b3c16ef17?w=800',
    'Keimyung University',
  ),
  _BannerItem(
    'https://images.unsplash.com/photo-1607013251379-e6eecfffe234?w=800',
    'Campus Life',
  ),
  _BannerItem(
    'https://images.unsplash.com/photo-1562774053-701939374585?w=800',
    'Study in Korea',
  ),
];

// ─────────────────────────── Screen ───────────────────────────
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({
    super.key,
    this.bannerCarouselAutoPlay = true,
  });

  /// When `false`, banner [CarouselSlider] does not auto-advance (e.g. widget
  /// tests, where autoPlay prevents [WidgetTester.pumpAndSettle] from idling).
  final bool bannerCarouselAutoPlay;

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final _scrollController = ScrollController();
  int _bannerIndex = 0;
  double _fabScale = 1.0;

  // Split mockPosts into sections
  static final _internationalPosts = mockPosts
      .where(
        (p) => p.category == 'International' || p.category == 'Scholarship',
      )
      .toList();
  static final _campusPosts = mockPosts
      .where((p) => p.category == 'Campus' || p.category == 'Academic')
      .toList();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolling =
        _scrollController.position.userScrollDirection != ScrollDirection.idle;
    final newScale = scrolling ? 0.85 : 1.0;
    if (newScale != _fabScale) setState(() => _fabScale = newScale);
  }

  void _openCreatePost() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      AppTransitions.fade(const CreatePostScreen()),
    );
  }

  void _openPostList() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      AppTransitions.fadeSlide(const PostListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mq = MediaQuery.of(context);
    // viewPadding: physical safe area; not reduced when keyboard opens (unlike padding.bottom).
    final safeBottom = mq.viewPadding.bottom;
    final navBarHeight = kBottomNavigationBarHeight + safeBottom;
    final fabBottomPadding = math.max(0.0, navBarHeight + 40.0);

    return Scaffold(
      backgroundColor: _T.background,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: fabBottomPadding),
        child: AnimatedScale(
          scale: _fabScale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _Fab(onTap: _openCreatePost),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildAppBar()),
          SliverToBoxAdapter(child: _buildBanner()),
          // ── International horizontal section ──
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: l.homeIntlNews,
              onViewAll: _openPostList,
            ),
          ),
          SliverToBoxAdapter(
            child: _internationalPosts.isEmpty
                ? const _EmptySection()
                : _buildInternationalList(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // ── Campus vertical section ──
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: l.homeCampusLife,
              onViewAll: _openPostList,
            ),
          ),
          if (_campusPosts.isEmpty)
            const SliverToBoxAdapter(child: _EmptySection())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, navBarHeight + 16),
              sliver: SliverList.separated(
                itemCount: _campusPosts.length,
                separatorBuilder: (context, i) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    PostCard(post: _campusPosts[i], style: PostCardStyle.list),
              ),
            ),
        ],
      ),
    );
  }

  // ─── App Bar ───
  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 4, 8),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HiCampus',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _T.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Keimyung University',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    color: _T.textGrey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const LanguagePickerButton(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
              color: _T.primary,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search_rounded),
              color: _T.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Banner ───
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 200,
              viewportFraction: 0.9,
              enlargeCenterPage: true,
              autoPlay: widget.bannerCarouselAutoPlay,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayCurve: Curves.easeInOutCubic,
              onPageChanged: (i, _) => setState(() => _bannerIndex = i),
            ),
            items: _banners.map((b) => _BannerCard(item: b)).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerIndex == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _bannerIndex == i
                      ? _T.primary
                      : _T.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── International horizontal list ───
  Widget _buildInternationalList() {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: _internationalPosts.length,
        separatorBuilder: (context, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) => PostCard(
          post: _internationalPosts[i],
          style: PostCardStyle.horizontal,
        ),
      ),
    );
  }
}

// ─────────────────────────── Banner Card ───────────────────────────
class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item});
  final _BannerItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_T.radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, e, s) => Container(
              color: _T.primary.withValues(alpha: 0.15),
              child: const Icon(
                Icons.image_outlined,
                color: _T.primary,
                size: 48,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Nguyen Van A 👋',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.caption,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

// ─────────────────────────── Empty Section ───────────────────────────
class _EmptySection extends StatelessWidget {
  const _EmptySection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 36, color: _T.primary.withValues(alpha: 0.25)),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.communityNoPosts,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: _T.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Section Header ───────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});
  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _T.primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: _T.textGrey,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.homeViewAll,
              style: GoogleFonts.notoSansKr(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── FAB ───────────────────────────
class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _T.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _T.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
