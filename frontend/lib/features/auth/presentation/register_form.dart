import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../data/register_picklist_data.dart';
import '../data/university_data.dart';
import '../providers/auth_provider.dart';
import '../theme/auth_theme.dart';
import '../utils/auth_validators.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/searchable_option_sheet.dart';

class RegisterForm extends HookWidget {
  const RegisterForm({super.key});

  void _snack(BuildContext context, String msg, {bool success = false}) {
    if (success) {
      showSuccessSnackBar(context, msg);
    } else {
      showErrorTextSnackBar(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final name = useTextEditingController();
    final emailId = useTextEditingController(); // part before @
    final password = useTextEditingController();
    final confirm = useTextEditingController();
    final obscure = useState(true);
    final obscureConfirm = useState(true);
    final loading = useState(false);
    final selectedUniversity = useState<University?>(null);
    final selectedDomain = useState<String?>(null);
    final selectedNationality = useState<String?>(null);
    final selectedNativeLanguage = useState<String?>(null);
    final showProfileFieldErrors = useState(false);

    // When university changes, reset domain to default
    useEffect(() {
      final uni = selectedUniversity.value;
      selectedDomain.value = uni?.defaultDomain;
      return null;
    }, [selectedUniversity.value]);

    String fullEmail() {
      final id = emailId.text.trim();
      final domain = selectedDomain.value ?? '';
      return domain.isEmpty ? id : combineEmail(id, domain);
    }

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final nat = selectedNationality.value?.trim();
      final lang = selectedNativeLanguage.value?.trim();
      if (nat == null || nat.isEmpty) {
        showProfileFieldErrors.value = true;
        return;
      }
      if (lang == null || lang.isEmpty) {
        showProfileFieldErrors.value = true;
        return;
      }
      showProfileFieldErrors.value = false;
      if (selectedUniversity.value == null) {
        _snack(context, l.authValidationUniversityEmail);
        return;
      }
      loading.value = true;
      try {
        await context.read<AuthProvider>().registerWithEmail(
              name: name.text.trim(),
              email: fullEmail(),
              password: password.text,
              nationality: nat,
              nativeLanguage: lang,
            );
        if (context.mounted) {
          _snack(context, l.authSuccessRegister, success: true);
        }
      } on FirebaseAuthException catch (e) {
        if (!context.mounted) return;
        final msg = switch (e.code) {
          'email-already-in-use' => l.authErrEmailInUse,
          'invalid-email'        => l.authErrInvalidEmail,
          'weak-password'        => l.authErrWeakPassword,
          _                      => l.authErrDefault(e.message ?? e.code),
        };
        _snack(context, msg);
      } finally {
        if (context.mounted) loading.value = false;
      }
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Full name ──────────────────────────────────────────────────
          AuthTextField(
            key: const Key('register_name'),
            controller: name,
            label: l.authFieldFullName,
            hint: l.authHintNameExample,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (v) => AuthValidators.name(v, l),
          ),
          const SizedBox(height: 16),

          RegisterSearchableField(
            key: const Key('register_nationality'),
            label: l.profileNationality,
            value: selectedNationality.value,
            placeholder: l.authRegisterSelectPlaceholder,
            leadingIcon: Icons.flag_outlined,
            errorText: showProfileFieldErrors.value &&
                    (selectedNationality.value == null ||
                        selectedNationality.value!.trim().isEmpty)
                ? l.authValidationNationalityEmpty
                : null,
            onTap: () async {
              final r = await showSearchableOptionSheet(
                context,
                title: l.profileNationality,
                searchHint: l.authRegisterSearchHint,
                options: kNationalityOptions,
                selected: selectedNationality.value,
              );
              if (r != null) {
                selectedNationality.value = r;
                showProfileFieldErrors.value = false;
              }
            },
          ),
          const SizedBox(height: 16),

          RegisterSearchableField(
            key: const Key('register_native_language'),
            label: l.profileNativeLang,
            value: selectedNativeLanguage.value,
            placeholder: l.authRegisterSelectPlaceholder,
            leadingIcon: Icons.translate_rounded,
            errorText: showProfileFieldErrors.value &&
                    (selectedNativeLanguage.value == null ||
                        selectedNativeLanguage.value!.trim().isEmpty)
                ? l.authValidationNativeLanguageEmpty
                : null,
            onTap: () async {
              final r = await showSearchableOptionSheet(
                context,
                title: l.profileNativeLang,
                searchHint: l.authRegisterSearchHint,
                options: kNativeLanguageOptions,
                selected: selectedNativeLanguage.value,
              );
              if (r != null) {
                selectedNativeLanguage.value = r;
                showProfileFieldErrors.value = false;
              }
            },
          ),
          const SizedBox(height: 16),

          // ── Email = [ID] @ [school picker] ────────────────────────────
          _EmailComposer(
            idController: emailId,
            selectedUniversity: selectedUniversity.value,
            selectedDomain: selectedDomain.value,
            onPickUniversity: () async {
              final uni = await _showUniversityPicker(context);
              if (uni != null) selectedUniversity.value = uni;
            },
            onDomainChanged: (d) => selectedDomain.value = d,
            idValidator: (v) => AuthValidators.localPart(v, l),
            universityValidator: () => selectedUniversity.value == null
                ? l.authValidationUniversityEmail
                : null,
          ),
          const SizedBox(height: 16),

          // ── Password ───────────────────────────────────────────────────
          AuthTextField(
            key: const Key('register_password'),
            controller: password,
            label: l.authFieldPassword,
            hint: l.authHintPasswordMin,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: obscure.value,
            showObscureToggle: true,
            onToggleObscure: () => obscure.value = !obscure.value,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) => AuthValidators.password(v, l),
          ),
          const SizedBox(height: 16),

          // ── Confirm password ───────────────────────────────────────────
          AuthTextField(
            key: const Key('register_confirm'),
            controller: confirm,
            label: l.authFieldPasswordConfirm,
            hint: l.authHintConfirmPassword,
            prefixIcon: Icons.verified_user_outlined,
            obscureText: obscureConfirm.value,
            showObscureToggle: true,
            onToggleObscure: () => obscureConfirm.value = !obscureConfirm.value,
            textInputAction: TextInputAction.done,
            validator: (v) => AuthValidators.confirmPassword(v, password.text, l),
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 24),

          AuthPrimaryButton(
            key: const Key('register_submit'),
            label: l.authButtonRegister,
            isLoading: loading.value,
            onPressed: submit,
          ),
        ],
      ),
    );
  }

  Future<University?> _showUniversityPicker(BuildContext context) {
    return showModalBottomSheet<University>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _UniversityPickerSheet(),
    );
  }
}

// ─────────────────────────── Email Composer ───────────────────────────────────
class _EmailComposer extends StatelessWidget {
  const _EmailComposer({
    required this.idController,
    required this.selectedUniversity,
    required this.selectedDomain,
    required this.onPickUniversity,
    required this.onDomainChanged,
    required this.idValidator,
    required this.universityValidator,
  });

  final TextEditingController idController;
  final University? selectedUniversity;
  final String? selectedDomain;
  final VoidCallback onPickUniversity;
  final void Function(String) onDomainChanged;
  final String? Function(String?) idValidator;
  final String? Function() universityValidator;

  @override
  Widget build(BuildContext context) {
    final uniError = universityValidator();
    final p = context.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'University Email',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),

        // ── Row: [ID field] @ [School picker] ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part 1 — ID before @
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: idController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  color: context.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                validator: idValidator,
                decoration: InputDecoration(
                  hintText: 'yourname',
                  hintStyle: TextStyle(
                    color: context.onSurfaceVar.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: context.subtleFill,
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    color: p,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuthRadii.sm),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuthRadii.sm),
                    borderSide: BorderSide(
                      color: context.outline.withValues(alpha: 0.9),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuthRadii.sm),
                    borderSide: BorderSide(
                      color: p,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuthRadii.sm),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .error
                          .withValues(alpha: 0.8),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AuthRadii.sm),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            // @ separator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
              child: Text(
                '@',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.onSurfaceVar.withValues(alpha: 0.6),
                ),
              ),
            ),

            // Part 2 — University picker button
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTap: onPickUniversity,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: context.subtleFill,
                    border: Border.all(
                      color: uniError != null
                          ? Theme.of(context).colorScheme.error
                          : context.outline.withValues(alpha: 0.9),
                    ),
                    borderRadius: BorderRadius.circular(AuthRadii.sm),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if (selectedUniversity != null) ...[
                        Text(selectedUniversity!.logo,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selectedDomain ?? selectedUniversity!.defaultDomain,
                            style: TextStyle(
                              fontSize: 12,
                              color: p,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ] else
                        Expanded(
                          child: Text(
                            'Select university',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  context.onSurfaceVar.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      Icon(Icons.expand_more_rounded,
                          size: 18, color: context.onSurfaceVar),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // University error message
        if (uniError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              uniError,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),

        // Part 3 — Sub-domain chips (shown when university has multiple domains)
        if (selectedUniversity != null && selectedUniversity!.hasMultipleDomains)
          _DomainChips(
            university: selectedUniversity!,
            selectedDomain: selectedDomain ?? selectedUniversity!.defaultDomain,
            onChanged: onDomainChanged,
          ),
      ],
    );
  }
}

// ─────────────────────────── Domain Chips ────────────────────────────────────
class _DomainChips extends StatelessWidget {
  const _DomainChips({
    required this.university,
    required this.selectedDomain,
    required this.onChanged,
  });

  final University university;
  final String selectedDomain;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.primary;
    final onP = Theme.of(context).colorScheme.onPrimary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: university.domains.map((domain) {
          final isSelected = domain == selectedDomain;
          return FilterChip(
            label: Text(
              '@$domain',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? onP : p,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onChanged(domain),
            backgroundColor: p.withValues(alpha: 0.06),
            selectedColor: p,
            checkmarkColor: onP,
            side: BorderSide(
              color: p.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────── University Picker ───────────────────────────────
class _UniversityPickerSheet extends StatefulWidget {
  const _UniversityPickerSheet();

  @override
  State<_UniversityPickerSheet> createState() => _UniversityPickerSheetState();
}

class _UniversityPickerSheetState extends State<_UniversityPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = searchUniversities(_query);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Select University',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.onSurface,
                  ),
            ),
            const SizedBox(height: 12),

            // Search field
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search university or domain…',
                prefixIcon:
                    const Icon(Icons.search_rounded, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),

            // University list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final uni = filtered[i];
                  return ListTile(
                    leading: Text(
                      uni.logo,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      uni.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      uni.domains.map((d) => '@$d').join('  ·  '),
                      style: TextStyle(
                        fontSize: 11,
                        color: context.primary,
                      ),
                    ),
                    dense: true,
                    onTap: () => Navigator.pop(context, uni),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
