import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/navigation/app_transitions.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../models/post.dart';
import '../post_detail_screen.dart';

// ─────────────────────────── Config Maps ───────────────────────────
class _LangConfig {
  const _LangConfig(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

const _langConfig = <String, _LangConfig>{
  'VN': _LangConfig(Color(0xFFFFECEC), Color(0xFFD32F2F)),
  'KR': _LangConfig(Color(0xFFE8F0FE), Color(0xFF2563EB)),
  'EN': _LangConfig(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  'JA': _LangConfig(Color(0xFFFFF3E0), Color(0xFFE65100)),
  'ZH': _LangConfig(Color(0xFFFFEBEE), Color(0xFFC62828)),
};

const _categoryColors = <String, Color>{
  'International': Color(0xFF2563EB),
  'Scholarship': Color(0xFF7B1FA2),
  'Campus': Color(0xFF00695C),
  'Housing': Color(0xFFE65100),
  'Academic': Color(0xFF1565C0),
};

// ─────────────────────────── Hero Tag Helpers ───────────────────────────
String postImageHeroTag(String postId) => 'post-thumb-$postId';
String postAvatarHeroTag(String postId) => 'post-avatar-$postId';

// ─────────────────────────── PostCard Style ───────────────────────────
enum PostCardStyle {
  /// Wide card in the horizontal Home carousel (width: 230).
  horizontal,

  /// Full-width card in vertical lists (Home campus + PostListScreen).
  list,
}

// ─────────────────────────── PostCard ───────────────────────────
/// Reusable post card. Handles its own navigation and image-absent layout.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.style = PostCardStyle.list,
  });

  final Post post;
  final PostCardStyle style;

  void _onTap(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      AppTransitions.fadeSlide(PostDetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      PostCardStyle.horizontal => _HorizontalCard(
          post: post,
          onTap: () => _onTap(context),
        ),
      PostCardStyle.list => _ListCard(
          post: post,
          onTap: () => _onTap(context),
        ),
    };
  }
}

// ─────────────────────────── Horizontal Card ───────────────────────────
class _HorizontalCard extends StatelessWidget {
  const _HorizontalCard({required this.post, required this.onTap});
  final Post post;
  final VoidCallback onTap;

  bool get _hasImage => post.images.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColors[post.category] ?? context.primary;
    final langCfg = _langConfig[post.language] ??
        _LangConfig(context.subtleFill, context.onSurfaceVar);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: context.cardFill,
          borderRadius: BorderRadius.circular(16),
          boxShadow: context.cardElevationShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (only when available) ──
            if (_hasImage)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Hero(
                  tag: postImageHeroTag(post.id),
                  child: _NetImage(
                    url: post.images.first,
                    width: double.infinity,
                    height: 110,
                  ),
                ),
              ),

            // ── Content ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  _hasImage ? 10 : 14,
                  12,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips
                    Row(
                      children: [
                        _MiniChip(
                          label: post.category,
                          bg: catColor.withValues(alpha: 0.1),
                          fg: catColor,
                        ),
                        const SizedBox(width: 5),
                        _MiniChip(
                          label: post.language,
                          bg: langCfg.bg,
                          fg: langCfg.fg,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    // Title — larger when no image so card feels intentional
                    Text(
                      post.title,
                      maxLines: _hasImage ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansKr(
                        fontSize: _hasImage ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: context.onSurface,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    // Author row
                    Row(
                      children: [
                        Hero(
                          tag: postAvatarHeroTag(post.id),
                          child: _AvatarCircle(
                            initial: post.author.avatarInitial,
                            size: 20,
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            post.author.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 10,
                              color: context.onSurfaceVar,
                            ),
                          ),
                        ),
                        Text(
                          post.time,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 10,
                            color: context.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── List Card ───────────────────────────
class _ListCard extends StatelessWidget {
  const _ListCard({required this.post, required this.onTap});
  final Post post;
  final VoidCallback onTap;

  bool get _hasImage => post.images.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColors[post.category] ?? context.primary;
    final langCfg = _langConfig[post.language] ??
        _LangConfig(context.subtleFill, context.onSurfaceVar);
    final p = context.primary;

    return Material(
      color: context.cardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: p.withValues(alpha: 0.05),
        highlightColor: p.withValues(alpha: 0.03),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: context.cardElevationShadow,
          ),
          child: _hasImage
              ? _withImage(context, catColor, langCfg)
              : _textOnly(context, catColor, langCfg),
        ),
      ),
    );
  }

  // ── Layout: has image — thumbnail left, content right ──
  Widget _withImage(
      BuildContext context, Color catColor, _LangConfig langCfg) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: postImageHeroTag(post.id),
              child: _NetImage(url: post.images.first, width: 84, height: 84),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: _contentColumn(context, catColor, langCfg,
                  compact: true)),
        ],
      ),
    );
  }

  // ── Layout: no image — full-width text + left blue border strip ──
  Widget _textOnly(
      BuildContext context, Color catColor, _LangConfig langCfg) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Full-width content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: _contentColumn(context, catColor, langCfg,
                    compact: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentColumn(
      BuildContext context, Color catColor, _LangConfig langCfg,
      {required bool compact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips
        Row(
          children: [
            _MiniChip(
              label: post.category,
              bg: catColor.withValues(alpha: 0.1),
              fg: catColor,
            ),
            const SizedBox(width: 6),
            _MiniChip(label: post.language, bg: langCfg.bg, fg: langCfg.fg),
          ],
        ),
        const SizedBox(height: 6),
        // Title — 3 lines when no image
        Text(
          post.title,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSansKr(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w700,
            color: context.onSurface,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        // Author + time
        Row(
          children: [
            Hero(
              tag: postAvatarHeroTag(post.id),
              child: _AvatarCircle(
                initial: post.author.avatarInitial,
                size: 20,
                fontSize: 9,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                post.author.name,
                style: GoogleFonts.notoSansKr(
                  fontSize: 12,
                  color: context.onSurfaceVar,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              post.time,
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: context.hintColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Stats
        Row(
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 13, color: context.hintColor),
            const SizedBox(width: 3),
            Text(
              '${post.likes}',
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: context.hintColor),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chat_bubble_outline_rounded,
                size: 13, color: context.hintColor),
            const SizedBox(width: 3),
            Text(
              '${post.comments}',
              style: GoogleFonts.notoSansKr(
                  fontSize: 11, color: context.hintColor),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────── Network Image with Shimmer + Error ───────────────────────────
class _NetImage extends StatelessWidget {
  const _NetImage({
    required this.url,
    this.width,
    this.height,
  });

  final String url;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      // ── Shimmer while loading ──
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Shimmer.fromColors(
          baseColor: dark ? const Color(0xFF2A2A2A) : const Color(0xFFE8ECF0),
          highlightColor:
              dark ? const Color(0xFF3D3D3D) : const Color(0xFFF5F7FA),
          child: Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      },
      // ── Elegant error placeholder ──
      errorBuilder: (context, error, stackTrace) {
        final muted = Theme.of(context).colorScheme.outline;
        final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
        return Container(
          width: width,
          height: height,
          color: fill,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: (height ?? 84) * 0.35,
                color: muted,
              ),
              if ((height ?? 0) > 60) ...[
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.postNoImage,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 10,
                    color: muted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Shared small widgets ───────────────────────────
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansKr(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.initial,
    this.size = 36,
    this.fontSize = 14,
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
