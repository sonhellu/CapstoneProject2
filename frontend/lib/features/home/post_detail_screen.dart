import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';
import 'models/post.dart';
import 'widgets/post_card.dart' show postImageHeroTag, postAvatarHeroTag;
import 'widgets/post_translator.dart';

const _langConfig = <String, _LangChip>{
  'VN': _LangChip(Color(0xFFFFECEC), Color(0xFFD32F2F)),
  'KR': _LangChip(Color(0xFFE8F0FE), Color(0xFF2563EB)),
  'EN': _LangChip(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  'JA': _LangChip(Color(0xFFFFF3E0), Color(0xFFE65100)),
  'ZH': _LangChip(Color(0xFFFFEBEE), Color(0xFFC62828)),
};

const _categoryColors = <String, Color>{
  'International': Color(0xFF2563EB),
  'Scholarship': Color(0xFF7B1FA2),
  'Campus': Color(0xFF00695C),
  'Housing': Color(0xFFE65100),
  'Academic': Color(0xFF1565C0),
};

// ─────────────────────────── Screen ───────────────────────────
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final Post post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  int _currentImageIndex = 0;
  final _pageCtrl = PageController();
  bool _isFollowing = false;
  late int _likeCount;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likes;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: widget.post.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.postCopied,
              style: GoogleFonts.notoSansKr(fontSize: 13),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────── Build ───────────────────────────
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final hasImages = post.images.isNotEmpty;

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: hasImages ? 300 : 0,
            pinned: true,
            backgroundColor: context.primary,
            elevation: 0,
            leading: _CircleNavButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              _CircleNavButton(
                icon: Icons.copy_rounded,
                onTap: _copyContent,
              ),
              _CircleNavButton(
                icon: Icons.share_rounded,
                onTap: () {},
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: hasImages
                ? FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Hero(
                      tag: postImageHeroTag(post.id),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _ImagePageView(
                            images: post.images,
                            controller: _pageCtrl,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0x00000000),
                                  Color(0x77000000),
                                ],
                              ),
                            ),
                          ),
                          if (post.images.length > 1)
                            Positioned(
                              bottom: 14,
                              left: 0,
                              right: 0,
                              child: _DotIndicator(
                                count: post.images.length,
                                current: _currentImageIndex,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),

          // ── Content card ──
          SliverToBoxAdapter(
            child: Container(
              color: context.cardFill,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow(context, post),
                    const SizedBox(height: 14),
                    _buildTitle(context, post),
                    const SizedBox(height: 20),
                    _buildAuthorRow(context, post),
                    const SizedBox(height: 24),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    const SizedBox(height: 24),
                    _buildBody(post.content, post.language),
                    const SizedBox(height: 32),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    const SizedBox(height: 20),
                    _buildActionBar(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Meta Row: chips + time ───
  Widget _buildMetaRow(BuildContext context, Post post) {
    final catColor = _categoryColors[post.category] ?? context.primary;
    final langCfg = _langConfig[post.language] ??
        _LangChip(context.subtleFill, context.onSurfaceVar);

    return Row(
      children: [
        _Chip(label: post.category, bg: catColor.withValues(alpha: 0.1), fg: catColor),
        const SizedBox(width: 8),
        _Chip(label: post.language, bg: langCfg.bg, fg: langCfg.fg),
        const Spacer(),
        Icon(Icons.access_time_rounded, size: 13, color: context.hintColor),
        const SizedBox(width: 4),
        Text(
          post.time,
          style: GoogleFonts.notoSansKr(fontSize: 12, color: context.hintColor),
        ),
      ],
    );
  }

  // ─── Title ───
  Widget _buildTitle(BuildContext context, Post post) {
    return Text(
      post.title,
      style: GoogleFonts.notoSansKr(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: context.primary,
        height: 1.35,
        letterSpacing: -0.5,
      ),
    );
  }

  // ─── Author Row ───
  Widget _buildAuthorRow(BuildContext context, Post post) {
    return Row(
      children: [
        Hero(
          tag: postAvatarHeroTag(post.id),
          child: _Avatar(initial: post.author.avatarInitial, size: 46, fontSize: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.name,
                style: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              // School · Major in one neat row
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.author.school,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: context.onSurfaceVar),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: context.hintColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      post.author.major,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: context.onSurfaceVar),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _FollowButton(
          isFollowing: _isFollowing,
          onTap: () => setState(() => _isFollowing = !_isFollowing),
        ),
      ],
    );
  }

  // ─── Body ───
  Widget _buildBody(String content, String langTag) {
    final deviceLang = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onLongPress: _copyContent,
      child: PostTranslator(
        text: content,
        postLangTag: langTag,
        deviceLangCode: deviceLang,
        textBuilder: (text) => Text(
          text,
          style: GoogleFonts.notoSansKr(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.8,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  // ─── Action Bar ───
  Widget _buildActionBar() {
    final l10n = AppLocalizations.of(context)!;
    final subtle = context.subtleFill;
    final muted = context.onSurfaceVar;
    return Row(
      children: [
        // Like
        Expanded(
          child: _ActionButton(
            icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: '$_likeCount',
            color: _isLiked ? Colors.redAccent : muted,
            bg: _isLiked
                ? Colors.redAccent.withValues(alpha: 0.12)
                : subtle,
            onTap: () => setState(() {
              _isLiked = !_isLiked;
              _likeCount += _isLiked ? 1 : -1;
            }),
          ),
        ),
        const SizedBox(width: 10),
        // Comment
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '${widget.post.comments}',
            color: muted,
            bg: subtle,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        // Save
        Expanded(
          child: _ActionButton(
            icon: Icons.bookmark_border_rounded,
            label: l10n.postActionSave,
            color: muted,
            bg: subtle,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Action Button ───────────────────────────
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Follow Button ───────────────────────────
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isFollowing, required this.onTap});
  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = context.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? context.subtleFill : p,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing ? context.outline : p,
          ),
        ),
        child: Text(
          isFollowing
              ? AppLocalizations.of(context)!.postFollowing
              : AppLocalizations.of(context)!.postFollow,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFollowing ? context.onSurfaceVar : cs.onPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Circle Nav Button ───────────────────────────
class _CircleNavButton extends StatelessWidget {
  const _CircleNavButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────── Image Page View ───────────────────────────
class _ImagePageView extends StatelessWidget {
  const _ImagePageView({
    required this.images,
    required this.controller,
    required this.onPageChanged,
  });

  final List<String> images;
  final PageController controller;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: images.length,
      onPageChanged: onPageChanged,
      itemBuilder: (ctx, i) => Image.network(
        images[i],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: ctx.primary.withValues(alpha: 0.08),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(ctx).colorScheme.outline,
            size: 48,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Dot Indicator ───────────────────────────
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white54,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────── Shared small widgets ───────────────────────────
class _LangChip {
  const _LangChip(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
            fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, this.size = 36, this.fontSize = 14});
  final String initial;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
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
