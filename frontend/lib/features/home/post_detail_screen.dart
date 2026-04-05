import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';

import 'models/post.dart';
import 'widgets/post_card.dart' show postImageHeroTag, postAvatarHeroTag;

// ─────────────────────────── Design Tokens ───────────────────────────
abstract final class _T {
  static const primary = Color(0xFF003478);
  static const background = Color(0xFFF5F7FA);
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6A6A6A);
  static const textLight = Color(0xFFADB5BD);
  static const surface = Colors.white;
  static const divider = Color(0xFFF0F0F0);
}

const _langConfig = <String, _LangChip>{
  'VN': _LangChip(Color(0xFFFFECEC), Color(0xFFD32F2F)),
  'KR': _LangChip(Color(0xFFE8F0FE), Color(0xFF003478)),
  'EN': _LangChip(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  'JA': _LangChip(Color(0xFFFFF3E0), Color(0xFFE65100)),
  'ZH': _LangChip(Color(0xFFFFEBEE), Color(0xFFC62828)),
};

const _categoryColors = <String, Color>{
  'International': Color(0xFF003478),
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
      backgroundColor: _T.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: hasImages ? 300 : 0,
            pinned: true,
            backgroundColor: _T.primary,
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

          // ── White card content ──
          SliverToBoxAdapter(
            child: Container(
              color: _T.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaRow(post),
                    const SizedBox(height: 14),
                    _buildTitle(post),
                    const SizedBox(height: 20),
                    _buildAuthorRow(post),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: _T.divider),
                    const SizedBox(height: 24),
                    _buildBody(post.content),
                    const SizedBox(height: 32),
                    const Divider(height: 1, color: _T.divider),
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
  Widget _buildMetaRow(Post post) {
    final catColor = _categoryColors[post.category] ?? _T.primary;
    final langCfg =
        _langConfig[post.language] ?? const _LangChip(Color(0xFFF0F0F0), _T.textGrey);

    return Row(
      children: [
        _Chip(label: post.category, bg: catColor.withValues(alpha: 0.1), fg: catColor),
        const SizedBox(width: 8),
        _Chip(label: post.language, bg: langCfg.bg, fg: langCfg.fg),
        const Spacer(),
        Icon(Icons.access_time_rounded, size: 13, color: _T.textLight),
        const SizedBox(width: 4),
        Text(
          post.time,
          style: GoogleFonts.notoSansKr(fontSize: 12, color: _T.textLight),
        ),
      ],
    );
  }

  // ─── Title ───
  Widget _buildTitle(Post post) {
    return Text(
      post.title,
      style: GoogleFonts.notoSansKr(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: _T.primary,
        height: 1.35,
        letterSpacing: -0.5,
      ),
    );
  }

  // ─── Author Row ───
  Widget _buildAuthorRow(Post post) {
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
                  color: _T.textDark,
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
                          fontSize: 11, color: _T.textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: _T.textLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      post.author.major,
                      style: GoogleFonts.notoSansKr(
                          fontSize: 11, color: _T.textGrey),
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
  Widget _buildBody(String content) {
    return GestureDetector(
      onLongPress: _copyContent,
      child: Text(
        content,
        style: GoogleFonts.notoSansKr(
          fontSize: 16,
          color: _T.textDark,
          height: 1.8,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ─── Action Bar ───
  Widget _buildActionBar() {
    return Row(
      children: [
        // Like
        _ActionButton(
          icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: '$_likeCount',
          color: _isLiked ? Colors.redAccent : _T.textGrey,
          bg: _isLiked ? const Color(0xFFFFEEEE) : const Color(0xFFF5F5F5),
          onTap: () => setState(() {
            _isLiked = !_isLiked;
            _likeCount += _isLiked ? 1 : -1;
          }),
        ),
        const SizedBox(width: 10),
        // Comment
        _ActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: '${widget.post.comments}',
          color: _T.textGrey,
          bg: const Color(0xFFF5F5F5),
          onTap: () {},
        ),
        const Spacer(),
        // Copy
        _ActionButton(
          icon: Icons.copy_rounded,
          label: AppLocalizations.of(context)!.postActionCopy,
          color: _T.primary,
          bg: _T.primary.withValues(alpha: 0.07),
          onTap: _copyContent,
        ),
        const SizedBox(width: 10),
        // Save
        _ActionButton(
          icon: Icons.bookmark_border_rounded,
          label: AppLocalizations.of(context)!.btnSave,
          color: _T.textGrey,
          bg: const Color(0xFFF5F5F5),
          onTap: () {},
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
          mainAxisSize: MainAxisSize.min,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? const Color(0xFFF5F7FA) : const Color(0xFF003478),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFollowing
                ? const Color(0xFFDDE3EA)
                : const Color(0xFF003478),
          ),
        ),
        child: Text(
          isFollowing ? AppLocalizations.of(context)!.postFollowing : AppLocalizations.of(context)!.postFollow,
          style: GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isFollowing ? const Color(0xFF6A6A6A) : Colors.white,
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
      itemBuilder: (context, i) => Image.network(
        images[i],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF003478).withValues(alpha: 0.08),
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFFCDD3D8),
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
