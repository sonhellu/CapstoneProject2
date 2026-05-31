import 'widgets/visa_d_day_card.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import '../../core/navigation/app_transitions.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/widgets/language_picker_button.dart';
import '../../l10n/app_localizations.dart';
import '../../core/locale/app_locale_resolver.dart';
import '../../core/services/webview_translation/webview_controller.dart';
import '../auth/data/university_data.dart';
import '../auth/providers/auth_provider.dart';
import 'create_post_screen.dart';
import 'models/post.dart';
import 'post_list_screen.dart';
import 'providers/post_provider.dart';
import 'widgets/post_card.dart';
import 'widgets/rent_section.dart';
import '../schedule/widgets/schedule_preview_widget.dart';

const double _kBannerRadius = 16.0;

// ─────────────────────────── Banner Data ───────────────────────────
class _BannerItem {
  final String imageAsset;
  final String caption;
  final String? websiteUrl;
  const _BannerItem(this.imageAsset, this.caption, {this.websiteUrl});
}

const Map<String, String> _universityImageAssets = {
  'Seoul National University': 'assets/university/seoul.jpg',
  'KAIST': 'assets/university/kaist.jpg',
  'Yonsei University': 'assets/university/yonsei.jpg',
  'Korea University': 'assets/university/korea.jpg',
  'POSTECH': 'assets/university/postch.jpg',
  'Sungkyunkwan University': 'assets/university/sungkyunkwan.jpg',
  'Keimyung University': 'assets/university/keimyung.jpeg',
  'Kyungpook National University': 'assets/university/kyungbook.jpg',
  'Yeungnam University': 'assets/university/yeungnam.jpg',
  'Daegu University': 'assets/university/daegu.jpg',
};

String _universityImageAsset(String uniName) {
  return _universityImageAssets[uniName] ?? 'assets/university/kmu_banner.jpg';
}

University? _findUniversity(String schoolName) {
  for (final uni in koreanUniversities) {
    if (uni.name == schoolName) return uni;
  }
  return null;
}

// ─────────────────────────── Screen ───────────────────────────
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key, this.bannerCarouselAutoPlay = true});

  /// When `false`, banner [CarouselSlider] does not auto-advance (e.g. widget
  /// tests, where autoPlay prevents [WidgetTester.pumpAndSettle] from idling).
  final bool bannerCarouselAutoPlay;

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final _scrollController = ScrollController();
  double _fabScale = 1.0;

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
    Navigator.of(context).push(AppTransitions.fade(const CreatePostScreen()));
  }

  void _openPostList() {
    HapticFeedback.lightImpact();
    Navigator.of(
      context,
    ).push(AppTransitions.fadeSlide(const PostListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final userName = auth.displayName ?? 'Student';
    final schoolName = auth.school ?? 'Keimyung University';
    final uni = _findUniversity(schoolName);
    final postProvider = context.watch<PostProvider>();
    final posts = postProvider.posts;
    final internationalPosts = posts
        .where(
          (p) => p.category == 'International' || p.category == 'Scholarship',
        )
        .toList(growable: false);
    final campusPosts = posts
        .where((p) => p.category == 'Campus' || p.category == 'Academic')
        .toList(growable: false);
    const fabBottomPadding = 24.0;
    final navBarHeight = kBottomNavigationBarHeight;

    return Scaffold(
      backgroundColor: context.bg,
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
          SliverToBoxAdapter(child: _buildAppBar(schoolName)),
          SliverToBoxAdapter(child: _buildBanner(userName, schoolName, uni)),
          const SliverToBoxAdapter(child: SchedulePreviewWidget()),
          // ── International horizontal section ──
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: VisaDDayCard(),
            ),
          ),
          const SliverToBoxAdapter(child: RentSection()),
          if (postProvider.isLoading)
            const SliverToBoxAdapter(child: _FeedLoadingSection())
          else if (postProvider.error != null)
            SliverToBoxAdapter(
              child: _FeedErrorSection(onRetry: () => postProvider.refresh()),
            )
          else ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: l.homeIntlNews,
                onViewAll: _openPostList,
              ),
            ),
            SliverToBoxAdapter(
              child: internationalPosts.isEmpty
                  ? const _EmptySection()
                  : _buildInternationalList(internationalPosts),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            // ── Campus vertical section ──
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: l.homeCampusLife,
                onViewAll: _openPostList,
              ),
            ),
            if (campusPosts.isEmpty)
              const SliverToBoxAdapter(child: _EmptySection())
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, navBarHeight + 16),
                sliver: SliverList.separated(
                  itemCount: campusPosts.length,
                  separatorBuilder: (context, i) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      PostCard(post: campusPosts[i], style: PostCardStyle.list),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ─── App Bar ───
  Widget _buildAppBar(String schoolName) {
    final p = context.primary;
    final gv = context.onSurfaceVar;
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
                    color: p,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  schoolName,
                  style: GoogleFonts.notoSansKr(fontSize: 12, color: gv),
                ),
              ],
            ),
            const Spacer(),
            const LanguagePickerButton(),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined),
              color: p,
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search_rounded),
              color: p,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Banner ───
  Widget _buildBanner(String userName, String schoolName, University? uni) {
    final item = _BannerItem(
      _universityImageAsset(schoolName),
      schoolName,
      websiteUrl: uni == null
          ? null
          : (uni.websiteUrl ?? 'https://www.${uni.defaultDomain}'),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SizedBox(
        height: 200,
        child: _BannerCard(item: item, userName: userName),
      ),
    );
  }

  // ─── International horizontal list ───
  Widget _buildInternationalList(List<Post> posts) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: posts.length,
        separatorBuilder: (context, i) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            PostCard(post: posts[i], style: PostCardStyle.horizontal),
      ),
    );
  }
}

// ─────────────────────────── Banner Card ───────────────────────────
class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item, required this.userName});
  final _BannerItem item;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    return GestureDetector(
      onTap: item.websiteUrl == null
          ? null
          : () => WebTranslation.open(
              context: context,
              url: item.websiteUrl!,
              title: item.caption,
              targetLangCode: AppLocaleResolver.targetLang(context),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kBannerRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              item.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: p.withValues(alpha: 0.15),
                child: Icon(Icons.image_outlined, color: p, size: 48),
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
                    'Welcome, $userName 👋',
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
            Icon(
              Icons.article_outlined,
              size: 36,
              color: context.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.communityNoPosts,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                color: context.onSurfaceVar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedLoadingSection extends StatelessWidget {
  const _FeedLoadingSection();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 128,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _FeedErrorSection extends StatelessWidget {
  const _FeedErrorSection({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: context.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.errorNetwork,
                style: GoogleFonts.notoSansKr(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.onSurfaceVar,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(l.alertTryAgain)),
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
              color: context.primary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: context.onSurfaceVar,
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
          color: context.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: context.primary.withValues(
                alpha: context.isDark ? 0.5 : 0.35,
              ),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          Icons.add_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }
}
