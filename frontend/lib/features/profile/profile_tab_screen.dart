import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/widgets/language_picker_button.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';

const double _kCardRadius = 16.0;

List<BoxShadow> _cardShadow(BuildContext context) => [
      BoxShadow(
        color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.08),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];

// ─────────────────────────── Mock Data ───────────────────────────
class _ProfileData {
  String fullName;
  String username;
  String nativeLanguage;
  String university;
  String major;
  String nationality;
  String email;

  _ProfileData({
    required this.fullName,
    required this.username,
    required this.nativeLanguage,
    required this.university,
    required this.major,
    required this.nationality,
    required this.email,
  });

  _ProfileData copyWith({
    String? fullName,
    String? username,
    String? nativeLanguage,
    String? university,
    String? major,
    String? nationality,
    String? email,
  }) =>
      _ProfileData(
        fullName: fullName ?? this.fullName,
        username: username ?? this.username,
        nativeLanguage: nativeLanguage ?? this.nativeLanguage,
        university: university ?? this.university,
        major: major ?? this.major,
        nationality: nationality ?? this.nationality,
        email: email ?? this.email,
      );
}

// ─────────────────────────── Screen ───────────────────────────
class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  bool _isEditMode = false;
  bool _isSaving = false;

  late _ProfileData _profile;
  late _ProfileData _editDraft;

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _langCtrl;

  static const _languages = [
    'Vietnamese', 'English', 'Korean', 'Japanese',
    'Chinese', 'Myanmar', 'Thai', 'French', 'Spanish',
  ];

  static const _nationalities = [
    'Vietnamese', 'Korean', 'Japanese', 'Chinese',
    'American', 'British', 'Myanmar', 'Thai', 'French',
  ];

  static const _universities = [
    'Keimyung University',
    'Kyungpook National University',
    'Yeungnam University',
    'Daegu University',
    'Seoul National University',
    'Yonsei University',
    'Korea University',
    'POSTECH',
    'KAIST',
    'Sungkyunkwan University',
  ];

  static const _majors = [
    'Computer Science',
    'Software Engineering',
    'Information Technology',
    'Electrical Engineering',
    'Business Administration',
    'Korean Language & Literature',
    'International Studies',
    'Economics',
    'Design',
    'Architecture',
  ];

  @override
  void initState() {
    super.initState();
    _profile = _ProfileData(
      fullName: 'Nguyen Van A',
      username: 'nguyenvana',
      nativeLanguage: 'Vietnamese',
      university: 'Keimyung University',
      major: 'Computer Science',
      nationality: 'Vietnamese',
      email: 'nguyenvana@kmu.ac.kr',
    );
    _editDraft = _profile.copyWith();
    _nameCtrl = TextEditingController(text: _profile.fullName);
    _langCtrl = TextEditingController(text: _profile.nativeLanguage);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _langCtrl.dispose();
    super.dispose();
  }

  bool get _isVerified => _profile.email.endsWith('.ac.kr');

  void _enterEdit() {
    _editDraft = _profile.copyWith();
    _nameCtrl.text = _profile.fullName;
    _langCtrl.text = _profile.nativeLanguage;
    setState(() => _isEditMode = true);
  }

  void _cancelEdit() => setState(() => _isEditMode = false);

  Future<void> _confirmLogout() async {
    final l = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.profileLogout,
          style: GoogleFonts.notoSansKr(
              fontWeight: FontWeight.w700, color: onSurface),
        ),
        content: Text(
          l.profileLogoutConfirm,
          style: GoogleFonts.notoSansKr(fontSize: 14, color: onSurfaceVar),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.btnCancel,
                style: GoogleFonts.notoSansKr(color: onSurfaceVar)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.profileLogout,
                style: GoogleFonts.notoSansKr(
                    color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() {
      _profile = _editDraft.copyWith(
        fullName: _nameCtrl.text.trim(),
      );
      _isEditMode = false;
      _isSaving = false;
    });
  }

  Future<void> _pickFromSheet({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PickerSheet(
        title: title,
        options: options,
        current: current,
        onSelected: (val) {
          onSelected(val);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ─── Build ───
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20, 24, 20,
            kBottomNavigationBarHeight +
                MediaQuery.of(context).padding.bottom +
                20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _isEditMode
                    ? _EditForm(
                        key: const ValueKey('edit'),
                        draft: _editDraft,
                        nameCtrl: _nameCtrl,
                        langCtrl: _langCtrl,
                        languages: _languages,
                        nationalities: _nationalities,
                        universities: _universities,
                        majors: _majors,
                        isSaving: _isSaving,
                        onPickLanguage: () => _pickFromSheet(
                          title: l.profileNativeLang,
                          options: _languages,
                          current: _editDraft.nativeLanguage,
                          onSelected: (v) => setState(() {
                            _editDraft = _editDraft.copyWith(nativeLanguage: v);
                            _langCtrl.text = v;
                          }),
                        ),
                        onPickUniversity: () => _pickFromSheet(
                          title: l.profileUniversity,
                          options: _universities,
                          current: _editDraft.university,
                          onSelected: (v) => setState(() {
                            _editDraft = _editDraft.copyWith(university: v);
                          }),
                        ),
                        onPickMajor: () => _pickFromSheet(
                          title: l.profileMajor,
                          options: _majors,
                          current: _editDraft.major,
                          onSelected: (v) => setState(() {
                            _editDraft = _editDraft.copyWith(major: v);
                          }),
                        ),
                        onPickNationality: () => _pickFromSheet(
                          title: l.profileNationality,
                          options: _nationalities,
                          current: _editDraft.nationality,
                          onSelected: (v) => setState(() {
                            _editDraft = _editDraft.copyWith(nationality: v);
                          }),
                        ),
                        onCancel: _cancelEdit,
                        onSave: _saveChanges,
                      )
                    : _DisplayCard(
                        key: const ValueKey('display'),
                        profile: _profile,
                        isVerified: _isVerified,
                      ),
              ),
              if (!_isEditMode) ...[
                const SizedBox(height: 20),
                _LogoutButton(onTap: _confirmLogout),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final primary = context.primary;
    return Column(
      children: [
        // ── Language + dark mode row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<ThemeController>(
              builder: (context, themeCtrl, _) {
                final dark =
                    Theme.of(context).brightness == Brightness.dark;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: 18,
                      color: primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.settingsDarkMode,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: dark,
                      onChanged: (v) => themeCtrl.setMode(
                        v ? ThemeMode.dark : ThemeMode.light,
                      ),
                    ),
                  ],
                );
              },
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => LanguageBottomSheet.show(context),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language_rounded,
                        size: 18, color: primary),
                    const SizedBox(width: 4),
                    Text(
                      l.settingsLanguage,
                      style: GoogleFonts.notoSansKr(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2),
                boxShadow: _cardShadow(context),
              ),
              child: CircleAvatar(
                radius: 52,
                backgroundColor: primary.withValues(alpha: 0.1),
                child: Text(
                  _profile.fullName.isNotEmpty
                      ? _profile.fullName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -4,
              right: -4,
              child: GestureDetector(
                onTap: _isEditMode ? null : _enterEdit,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                    boxShadow: _cardShadow(context),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _profile.fullName,
          style: GoogleFonts.notoSansKr(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: context.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${_profile.username}',
          style: GoogleFonts.notoSansKr(
            fontSize: 14,
            color: context.onSurfaceVar,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Display Card ───────────────────────────
class _DisplayCard extends StatelessWidget {
  const _DisplayCard({super.key, required this.profile, required this.isVerified});

  final _ProfileData profile;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Card(
      title: l.profilePersonalInfo,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.language_outlined,
            label: l.profileNativeLang,
            value: profile.nativeLanguage,
          ),
          _divider(context),
          _InfoRow(
            icon: Icons.school_outlined,
            label: l.profileUniversity,
            value: profile.university,
            badge: isVerified
                ? const _VerifiedBadge()
                : null,
          ),
          _divider(context),
          _InfoRow(
            icon: Icons.menu_book_outlined,
            label: l.profileMajor,
            value: profile.major,
          ),
          _divider(context),
          _InfoRow(
            icon: Icons.flag_outlined,
            label: l.profileNationality,
            value: profile.nationality,
          ),
          _divider(context),
          _InfoRow(
            icon: Icons.email_outlined,
            label: l.profileEmail,
            value: profile.email,
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) =>
      Divider(height: 1, color: Theme.of(context).dividerColor);
}

// ─────────────────────────── Edit Form ───────────────────────────
class _EditForm extends StatelessWidget {
  const _EditForm({
    super.key,
    required this.draft,
    required this.nameCtrl,
    required this.langCtrl,
    required this.languages,
    required this.nationalities,
    required this.universities,
    required this.majors,
    required this.isSaving,
    required this.onPickLanguage,
    required this.onPickUniversity,
    required this.onPickMajor,
    required this.onPickNationality,
    required this.onCancel,
    required this.onSave,
  });

  final _ProfileData draft;
  final TextEditingController nameCtrl;
  final TextEditingController langCtrl;
  final List<String> languages;
  final List<String> nationalities;
  final List<String> universities;
  final List<String> majors;
  final bool isSaving;
  final VoidCallback onPickLanguage;
  final VoidCallback onPickUniversity;
  final VoidCallback onPickMajor;
  final VoidCallback onPickNationality;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          title: l.profileEditInfo,
          child: Column(
            children: [
              _Field(
                icon: Icons.person_outline_rounded,
                label: l.profileFullName,
                controller: nameCtrl,
              ),
              const SizedBox(height: 16),
              _TapField(
                icon: Icons.language_outlined,
                label: l.profileNativeLang,
                value: draft.nativeLanguage,
                onTap: onPickLanguage,
              ),
              const SizedBox(height: 16),
              _TapField(
                icon: Icons.school_outlined,
                label: l.profileUniversity,
                value: draft.university,
                onTap: onPickUniversity,
              ),
              const SizedBox(height: 16),
              _TapField(
                icon: Icons.menu_book_outlined,
                label: l.profileMajor,
                value: draft.major,
                onTap: onPickMajor,
              ),
              const SizedBox(height: 16),
              _TapField(
                icon: Icons.flag_outlined,
                label: l.profileNationality,
                value: draft.nationality,
                onTap: onPickNationality,
              ),
              const SizedBox(height: 16),
              _Field(
                icon: Icons.email_outlined,
                label: l.profileEmail,
                controller: TextEditingController(text: draft.email),
                readOnly: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Save button
        _SaveButton(isSaving: isSaving, onSave: onSave),
        const SizedBox(height: 12),
        // Cancel
        TextButton(
          onPressed: isSaving ? null : onCancel,
          child: Text(
            l.btnCancel,
            style: GoogleFonts.notoSansKr(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Shared Widgets ───────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: _cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: GoogleFonts.notoSansKr(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.primary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 11,
                    color: context.onSurfaceVar,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.notoSansKr(
                          fontSize: 14,
                          color: context.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      badge!,
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: p.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 12, color: p),
          const SizedBox(width: 3),
          Text(
            AppLocalizations.of(context)!.profileVerified,
            style: GoogleFonts.notoSansKr(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: p,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.label,
    required this.controller,
    this.readOnly = false,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final outline = context.outline;
    final p = context.primary;
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: GoogleFonts.notoSansKr(
        fontSize: 14,
        color: readOnly ? context.onSurfaceVar : context.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.notoSansKr(fontSize: 13, color: context.onSurfaceVar),
        prefixIcon: Icon(icon, size: 20, color: p),
        filled: true,
        fillColor: readOnly ? context.surfaceVar : context.cardFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  const _TapField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: context.cardFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.outline),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 11,
                      color: context.onSurfaceVar,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: context.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: context.onSurfaceVar, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isSaving ? null : onSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          disabledBackgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                AppLocalizations.of(context)!.profileSaveChanges,
                style: GoogleFonts.notoSansKr(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────── Logout Button ───────────────────────────
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
        label: Text(
          AppLocalizations.of(context)!.profileLogout,
          style: GoogleFonts.notoSansKr(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          side: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────── Picker Sheet ───────────────────────────
class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.current,
    required this.onSelected,
  });

  final String title;
  final List<String> options;
  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.notoSansKr(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: context.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            itemBuilder: (_, i) {
              final opt = options[i];
              final selected = opt == current;
              return ListTile(
                onTap: () => onSelected(opt),
                title: Text(
                  opt,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
