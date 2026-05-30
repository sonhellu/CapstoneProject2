import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_ext.dart';
import '../../l10n/app_localizations.dart';

class VisaInfoFormScreen extends StatefulWidget {
  const VisaInfoFormScreen({super.key});

  @override
  State<VisaInfoFormScreen> createState() => _VisaInfoFormScreenState();
}

class _VisaInfoFormScreenState extends State<VisaInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _registrationNumberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _visaTypeCtrl = TextEditingController();
  final _addressReportDateCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  DateTime? _permissionDate;
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _registrationNumberCtrl.dispose();
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _visaTypeCtrl.dispose();
    _addressReportDateCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) onPicked(picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.visaDateSelect;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    if (_permissionDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visaSelectDateError)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.visaLoginRequired)),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visaInfo')
          .doc('current')
          .set({
        'registrationNumber': _registrationNumberCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'visaType': _visaTypeCtrl.text.trim(),
        'permissionDate': Timestamp.fromDate(_permissionDate!),
        'expiryDate': Timestamp.fromDate(_expiryDate!),
        'addressReportDate': _addressReportDateCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.visaSaveSuccess)),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.visaSaveFailed}$e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        title: Text(
          l10n.visaFormTitle,
          style: GoogleFonts.notoSansKr(
            fontWeight: FontWeight.w700,
            color: context.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _InputField(
                  controller: _registrationNumberCtrl,
                  label: l10n.visaFieldRegNumber,
                  hintText: l10n.visaFieldRegNumberHint,
                  requiredMsg: l10n.visaFieldRequired,
                  icon: Icons.badge_outlined,
                ),
                _InputField(
                  controller: _nameCtrl,
                  label: l10n.visaFieldName,
                  hintText: l10n.visaFieldNameHint,
                  requiredMsg: l10n.visaFieldRequired,
                  icon: Icons.person_outline,
                ),
                _InputField(
                  controller: _countryCtrl,
                  label: l10n.visaFieldCountry,
                  hintText: l10n.visaFieldCountryHint,
                  requiredMsg: l10n.visaFieldRequired,
                  icon: Icons.flag_outlined,
                ),
                _InputField(
                  controller: _visaTypeCtrl,
                  label: l10n.visaFieldVisaType,
                  hintText: l10n.visaFieldVisaTypeHint,
                  requiredMsg: l10n.visaFieldRequired,
                  icon: Icons.school_outlined,
                ),
                _DateTile(
                  label: l10n.visaFieldPermissionDate,
                  value: _formatDate(_permissionDate),
                  isSelected: _permissionDate != null,
                  icon: Icons.event_available_outlined,
                  onTap: () => _pickDate(
                    initialDate: _permissionDate,
                    onPicked: (date) => setState(() => _permissionDate = date),
                  ),
                ),
                _DateTile(
                  label: l10n.visaFieldExpiryDate,
                  value: _formatDate(_expiryDate),
                  isSelected: _expiryDate != null,
                  icon: Icons.event_busy_outlined,
                  onTap: () => _pickDate(
                    initialDate: _expiryDate,
                    onPicked: (date) => setState(() => _expiryDate = date),
                  ),
                ),
                _InputField(
                  controller: _addressReportDateCtrl,
                  label: l10n.visaFieldAddressReportDate,
                  hintText: l10n.visaFieldAddressReportDateHint,
                  requiredMsg: l10n.visaFieldRequired,
                  icon: Icons.edit_calendar_outlined,
                ),
                _InputField(
                  controller: _addressCtrl,
                  label: l10n.visaFieldAddress,
                  hintText: l10n.visaFieldAddressHint,
                  requiredMsg: l10n.visaFieldRequired,
                  icon: Icons.home_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.visaSaveButton,
                            style: GoogleFonts.notoSansKr(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.requiredMsg,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String requiredMsg;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) =>
            (value == null || value.trim().isEmpty) ? requiredMsg : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            labelText: label,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            value,
            style: GoogleFonts.notoSansKr(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
