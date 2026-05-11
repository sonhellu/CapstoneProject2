import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/theme_ext.dart';

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

    if (picked != null) {
      onPicked(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '선택';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_permissionDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('허가일자와 만료일자를 선택해주세요.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비자 정보가 저장되었습니다.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        title: Text(
          '비자 정보 입력',
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
                  label: '외국인등록번호',
                  hintText: '예: 000000-0000000',
                  icon: Icons.badge_outlined,
                ),
                _InputField(
                  controller: _nameCtrl,
                  label: '성명',
                  hintText: '외국인등록증에 적힌 이름',
                  icon: Icons.person_outline,
                ),
                _InputField(
                  controller: _countryCtrl,
                  label: '국가/지역',
                  hintText: '예: Vietnam',
                  icon: Icons.flag_outlined,
                ),
                _InputField(
                  controller: _visaTypeCtrl,
                  label: '체류자격',
                  hintText: '예: D-2',
                  icon: Icons.school_outlined,
                ),
                _DateTile(
                  label: '허가일자',
                  value: _formatDate(_permissionDate),
                  icon: Icons.event_available_outlined,
                  onTap: () => _pickDate(
                    initialDate: _permissionDate,
                    onPicked: (date) {
                      setState(() => _permissionDate = date);
                    },
                  ),
                ),
                _DateTile(
                  label: '만료일자',
                  value: _formatDate(_expiryDate),
                  icon: Icons.event_busy_outlined,
                  onTap: () => _pickDate(
                    initialDate: _expiryDate,
                    onPicked: (date) {
                      setState(() => _expiryDate = date);
                    },
                  ),
                ),
                _InputField(
                  controller: _addressReportDateCtrl,
                  label: '체류지 신고일',
                  hintText: '예: 2026.05.11',
                  icon: Icons.edit_calendar_outlined,
                ),
                _InputField(
                  controller: _addressCtrl,
                  label: '체류지',
                  hintText: '현재 거주 주소',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      '저장하기',
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
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label을(를) 입력해주세요.';
          }
          return null;
        },
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
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value != '선택';

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
              color: isSelected ? context.onSurface : context.onSurfaceVar,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}