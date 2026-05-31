import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import 'models/post.dart';
import 'providers/post_provider.dart';

const Color _kWarningOrange = Color(0xFFE65100);

// ──────────────────────────── Config ────────────────────────────
abstract final class _Cfg {
  static const titleMax = 100;
  static const contentMax = 2000;
  static const maxPhotoBytes = 5 * 1024 * 1024;
  static const photoUrlRetryDelays = [
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(milliseconds: 900),
  ];

  static const categories = [
    'International 🌏',
    'Campus 🇰🇷',
    'Scholarship 🎓',
    'Housing 🏠',
    'Academic 📚',
    'Lost & Found 🔍',
  ];

  static const languages = [
    'Korean',
    'Vietnamese',
    'English',
    'Japanese',
    'Chinese',
    'Myanmar',
  ];

  static const langFlags = {
    'Korean': '🇰🇷',
    'Vietnamese': '🇻🇳',
    'English': '🇺🇸',
    'Japanese': '🇯🇵',
    'Chinese': '🇨🇳',
    'Myanmar': '🇲🇲',
  };
}

// ──────────────────────────── Screen ────────────────────────────
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _titleFocus = FocusNode();
  final _contentFocus = FocusNode();

  String _category = _Cfg.categories[0];
  String _language = 'Vietnamese';
  bool _isPublishing = false;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  String? _selectedPhotoContentType;

  final _imagePicker = ImagePicker();
  late final ValueNotifier<bool> _canPublish;

  @override
  void initState() {
    super.initState();
    _canPublish = ValueNotifier(false);
    _titleCtrl.addListener(_onTextChanged);
    _contentCtrl.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _titleFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTextChanged);
    _contentCtrl.removeListener(_onTextChanged);
    _canPublish.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _canPublish.value =
        _titleCtrl.text.trim().isNotEmpty &&
        _contentCtrl.text.trim().isNotEmpty;
  }

  Future<void> _publish() async {
    if (!_canPublish.value || _isPublishing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPublishing = true);

    String? uploadedImageUrl;
    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.uid;
      if (uid == null) {
        throw Exception('Please sign in before publishing.');
      }
      final authorName = auth.nickname;

      if (!mounted) return;

      uploadedImageUrl = await _uploadSelectedPhoto(uid);
      if (!mounted) {
        if (uploadedImageUrl != null) {
          unawaited(_deleteUploadedPhoto(uploadedImageUrl));
        }
        return;
      }

      final post = Post(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        author: PostAuthor(
          name: authorName,
          school: auth.school ?? 'Keimyung University',
          major: 'International Student',
          avatarInitial: authorName.characters.first.toUpperCase(),
        ),
        time: 'Just now',
        category: _normalizeCategory(_category),
        images: uploadedImageUrl == null ? const [] : [uploadedImageUrl],
        language: _normalizeLanguage(_language),
        likes: 0,
        comments: 0,
        userId: uid,
      );

      await context.read<PostProvider>().addPost(post);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (uploadedImageUrl != null) {
        unawaited(_deleteUploadedPhoto(uploadedImageUrl));
      }
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_publishFailedMessage(context, e))),
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPublishing) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.lengthInBytes > _Cfg.maxPhotoBytes) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_photoTooLargeMessage(context))));
        return;
      }

      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoName = picked.name;
        _selectedPhotoContentType = _contentTypeForPickedImage(picked);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_photoPickFailedMessage(context))));
    }
  }

  Future<String?> _uploadSelectedPhoto(String uid) async {
    final bytes = _selectedPhotoBytes;
    if (bytes == null) return null;

    final contentType = _selectedPhotoContentType ?? 'image/jpeg';
    final ext = _extensionForContentType(contentType);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref('posts/$uid/$fileName');
    final snapshot = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return _downloadUrlWithRetry(snapshot.ref);
  }

  Future<String> _downloadUrlWithRetry(Reference ref) async {
    for (
      var attempt = 0;
      attempt <= _Cfg.photoUrlRetryDelays.length;
      attempt++
    ) {
      try {
        await ref.getMetadata();
        return await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        final canRetry =
            e.code == 'object-not-found' &&
            attempt < _Cfg.photoUrlRetryDelays.length;
        if (!canRetry) rethrow;
        await Future<void>.delayed(_Cfg.photoUrlRetryDelays[attempt]);
      }
    }
    return ref.getDownloadURL();
  }

  Future<void> _deleteUploadedPhoto(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
    } catch (_) {}
  }

  void _removeSelectedPhoto() {
    if (_isPublishing) return;
    setState(() {
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
      _selectedPhotoContentType = null;
    });
  }

  String _contentTypeForPickedImage(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;

    final lowerName = image.name.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.heic')) return 'image/heic';
    if (lowerName.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  String _extensionForContentType(String contentType) {
    return switch (contentType.toLowerCase()) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' => 'heic',
      'image/heif' => 'heif',
      _ => 'jpg',
    };
  }

  String _photoTooLargeMessage(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'ko' => '사진은 5MB 이하로 선택해 주세요.',
      'en' => 'Please choose an image under 5 MB.',
      'ja' => '5MB以下の画像を選択してください。',
      'zh' => '请选择小于 5 MB 的图片。',
      'my' => '5 MB အောက်ရှိ ပုံကို ရွေးပါ။',
      _ => 'Vui lòng chọn ảnh dưới 5 MB.',
    };
  }

  String _photoPickFailedMessage(BuildContext context) {
    return switch (Localizations.localeOf(context).languageCode) {
      'ko' => '사진을 불러오지 못했습니다.',
      'en' => 'Could not load the image.',
      'ja' => '画像を読み込めませんでした。',
      'zh' => '无法加载图片。',
      'my' => 'ပုံကို ဖွင့်၍မရပါ။',
      _ => 'Không thể tải ảnh.',
    };
  }

  String _publishFailedMessage(BuildContext context, Object error) {
    if (error is FirebaseException && error.plugin == 'firebase_storage') {
      return _storageErrorMessage(context, error.code);
    }

    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('[firebase_storage/object-not-found]')) {
      return _storageErrorMessage(context, 'object-not-found');
    }
    if (message.contains('[firebase_storage/unauthorized]')) {
      return _storageErrorMessage(context, 'unauthorized');
    }
    return message;
  }

  String _storageErrorMessage(BuildContext context, String code) {
    final lang = Localizations.localeOf(context).languageCode;
    if (code == 'object-not-found') {
      return switch (lang) {
        'ko' => 'Firebase Storage가 아직 설정되지 않았습니다. Storage를 활성화한 뒤 다시 시도해 주세요.',
        'en' =>
          'Firebase Storage is not set up yet. Enable Storage, deploy rules, then try again.',
        'ja' => 'Firebase Storage が未設定です。Storage を有効化してルールをデプロイしてください。',
        'zh' => 'Firebase Storage 尚未设置。请先启用 Storage 并部署规则。',
        'my' =>
          'Firebase Storage မသတ်မှတ်ရသေးပါ။ Storage ကိုဖွင့်ပြီး rules deploy လုပ်ပါ။',
        _ =>
          'Firebase Storage chưa được bật. Hãy bật Storage, deploy rules rồi thử lại.',
      };
    }
    if (code == 'unauthorized') {
      return switch (lang) {
        'ko' => '사진 업로드 권한이 없습니다. Storage rules를 확인해 주세요.',
        'en' => 'No permission to upload images. Please check Storage rules.',
        'ja' => '画像をアップロードする権限がありません。Storage rules を確認してください。',
        'zh' => '没有上传图片权限。请检查 Storage rules。',
        'my' => 'ပုံတင်ရန် ခွင့်ပြုချက်မရှိပါ။ Storage rules ကို စစ်ဆေးပါ။',
        _ => 'Chưa có quyền upload ảnh. Hãy kiểm tra Firebase Storage rules.',
      };
    }
    return switch (lang) {
      'ko' => '사진을 업로드하지 못했습니다.',
      'en' => 'Could not upload the image.',
      'ja' => '画像をアップロードできませんでした。',
      'zh' => '无法上传图片。',
      'my' => 'ပုံကို upload လုပ်၍မရပါ။',
      _ => 'Không thể upload ảnh.',
    };
  }

  String _normalizeCategory(String category) => switch (category) {
    'International 🌏' => 'International',
    'Campus 🇰🇷' => 'Campus',
    'Scholarship 🎓' => 'Scholarship',
    'Housing 🏠' => 'Housing',
    'Academic 📚' => 'Academic',
    'Lost & Found 🔍' => 'Campus',
    _ => 'Campus',
  };

  String _normalizeLanguage(String language) => switch (language) {
    'Korean' => 'KR',
    'Vietnamese' => 'VN',
    'English' => 'EN',
    'Japanese' => 'JA',
    'Chinese' => 'ZH',
    'Myanmar' => 'MY',
    _ => 'EN',
  };

  void _openLanguagePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        final p = ctx.primary;
        final onS = ctx.onSurface;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.createPostLanguage,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: onS,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _Cfg.languages.length,
                  itemBuilder: (_, i) {
                    final lang = _Cfg.languages[i];
                    final flag = _Cfg.langFlags[lang] ?? '🌐';
                    final isSel = lang == _language;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      leading: Text(flag, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        lang,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          color: isSel ? p : onS,
                        ),
                      ),
                      trailing: isSel
                          ? Icon(Icons.check_rounded, color: p)
                          : null,
                      onTap: () {
                        setState(() => _language = lang);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: context.cardFill,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: 22,
            color: context.onSurfaceVar,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context)!.createPostNew,
          style: GoogleFonts.notoSansKr(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          // ── Category ──
          _Label(l.createPostCategory),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _Cfg.categories
                .map(
                  (cat) => _CategoryChip(
                    label: cat,
                    selected: _category == cat,
                    onTap: () => setState(() => _category = cat),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),

          // ── Title ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label(l.createPostTitleLabel),
              _CharCounter(ctrl: _titleCtrl, max: _Cfg.titleMax),
            ],
          ),
          const SizedBox(height: 10),
          _FieldBox(
            child: TextField(
              controller: _titleCtrl,
              focusNode: _titleFocus,
              maxLength: _Cfg.titleMax,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              inputFormatters: [
                LengthLimitingTextInputFormatter(_Cfg.titleMax),
              ],
              style: GoogleFonts.notoSansKr(
                fontSize: 15,
                color: context.onSurface,
                height: 1.4,
              ),
              textInputAction: TextInputAction.next,
              onEditingComplete: _contentFocus.requestFocus,
              decoration: InputDecoration.collapsed(
                hintText: l.createPostTitleHint,
                hintStyle: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  color: context.hintColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Language ──
          _Label(l.createPostLanguage),
          const SizedBox(height: 10),
          _buildLanguageTile(),
          const SizedBox(height: 20),

          // ── Content ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Label(l.createPostContent),
              _CharCounter(ctrl: _contentCtrl, max: _Cfg.contentMax),
            ],
          ),
          const SizedBox(height: 10),
          _FieldBox(
            child: TextField(
              controller: _contentCtrl,
              focusNode: _contentFocus,
              maxLines: null,
              minLines: 7,
              maxLength: _Cfg.contentMax,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              style: GoogleFonts.notoSansKr(
                fontSize: 14,
                color: context.onSurface,
                height: 1.75,
              ),
              decoration: InputDecoration.collapsed(
                hintText: l.createPostContentHint,
                hintStyle: GoogleFonts.notoSansKr(
                  fontSize: 14,
                  color: context.hintColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Photo ──
          _PhotoPickerSection(
            imageBytes: _selectedPhotoBytes,
            fileName: _selectedPhotoName,
            isPublishing: _isPublishing,
            onGallery: () => _pickPhoto(ImageSource.gallery),
            onCamera: () => _pickPhoto(ImageSource.camera),
            onRemove: _removeSelectedPhoto,
          ),
          const SizedBox(height: 32),

          // ── Publish — only this widget rebuilds when typing ──
          ValueListenableBuilder<bool>(
            valueListenable: _canPublish,
            builder: (_, can, _) => _PublishButton(
              enabled: can && !_isPublishing,
              isPublishing: _isPublishing,
              onTap: _publish,
            ),
          ),
        ],
      ),
    );
  }

  // ── Builders ────────────────────────────────────────────────────────

  Widget _buildLanguageTile() {
    final flag = _Cfg.langFlags[_language] ?? '🌐';
    final p = context.primary;
    return ListTile(
      onTap: _openLanguagePicker,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: context.cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.outline),
      ),
      leading: Icon(Icons.translate_rounded, color: p, size: 20),
      title: Text(
        '$flag  $_language',
        style: GoogleFonts.notoSansKr(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.onSurface,
        ),
      ),
      subtitle: Text(
        AppLocalizations.of(context)!.createPostLanguage,
        style: GoogleFonts.notoSansKr(fontSize: 11, color: p),
      ),
      trailing: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: context.onSurfaceVar,
      ),
    );
  }
}

// ──────────────────────────── _FieldBox ────────────────────────────
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.outline),
      ),
      child: child,
    );
  }
}

// ──────────────────────────── _Label ────────────────────────────
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansKr(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: context.onSurfaceVar,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ──────────────────────────── _CharCounter ────────────────────────────
class _CharCounter extends StatelessWidget {
  const _CharCounter({required this.ctrl, required this.max});
  final TextEditingController ctrl;
  final int max;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: ctrl,
      builder: (_, val, _) {
        final len = val.text.length;
        final ratio = len / max;
        final color = ratio >= 0.95
            ? Theme.of(context).colorScheme.error
            : ratio >= 0.80
            ? _kWarningOrange
            : context.hintColor;
        return Text(
          '$len / $max',
          style: GoogleFonts.notoSansKr(fontSize: 11, color: color),
        );
      },
    );
  }
}

// ──────────────────────────── _PhotoPickerSection ────────────────────────────
class _PhotoPickerSection extends StatelessWidget {
  const _PhotoPickerSection({
    required this.imageBytes,
    required this.fileName,
    required this.isPublishing,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
  });

  final Uint8List? imageBytes;
  final String? fileName;
  final bool isPublishing;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;

  bool get hasImage => imageBytes != null;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(l.createPostPhotos),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: hasImage
              ? _SelectedPhotoPreview(
                  key: const ValueKey('selected-photo'),
                  imageBytes: imageBytes!,
                  fileName: fileName,
                  enabled: !isPublishing,
                  onRemove: onRemove,
                )
              : Container(
                  key: const ValueKey('empty-photo'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.outline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          color: context.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.createPostAddPhoto,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.createPostGallery,
                        onPressed: isPublishing ? null : onGallery,
                        icon: Icon(
                          Icons.photo_library_rounded,
                          color: isPublishing ? cs.outline : context.primary,
                        ),
                      ),
                      IconButton(
                        tooltip: l.createPostCamera,
                        onPressed: isPublishing ? null : onCamera,
                        icon: Icon(
                          Icons.photo_camera_rounded,
                          color: isPublishing ? cs.outline : context.primary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        if (hasImage) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPublishing ? null : onGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 18),
                  label: Text(
                    l.createPostGallery,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPublishing ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_rounded, size: 18),
                  label: Text(
                    l.createPostCamera,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SelectedPhotoPreview extends StatelessWidget {
  const _SelectedPhotoPreview({
    super.key,
    required this.imageBytes,
    required this.fileName,
    required this.enabled,
    required this.onRemove,
  });

  final Uint8List imageBytes;
  final String? fileName;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(imageBytes, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.42),
                  ],
                  stops: const [0, 0.52, 1],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ),
            if (fileName != null && fileName!.isNotEmpty)
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Text(
                  fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── _PublishButton ────────────────────────────
class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.enabled,
    required this.isPublishing,
    required this.onTap,
  });
  final bool enabled;
  final bool isPublishing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primary,
          disabledBackgroundColor: context.primary.withValues(alpha: 0.45),
          foregroundColor: cs.onPrimary,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: isPublishing
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                ),
              )
            : Text(
                AppLocalizations.of(context)!.createPostPublish,
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ──────────────────────────── _CategoryChip ────────────────────────────
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.primary : context.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? context.primary : context.outline,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSansKr(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? cs.onPrimary : context.onSurfaceVar,
          ),
        ),
      ),
    );
  }
}
