import 'package:flutter/material.dart';

import '../../data/options.dart';
import '../../models/onboarding_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class ExperienceStep extends StatefulWidget {
  const ExperienceStep({super.key, required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<ExperienceStep> createState() => _ExperienceStepState();
}

class _ExperienceStepState extends State<ExperienceStep> {
  late final _title = TextEditingController(text: widget.data.jobTitle);
  late final _company = TextEditingController(text: widget.data.company);

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    super.dispose();
  }

  OnboardingData get d => widget.data;

  Future<void> _select(String title, List<String> options, String? current,
      void Function(String) apply) async {
    final v = await showPickerSheet(context,
        title: title, options: options, selected: current);
    if (v != null) d.set(() => apply(v));
  }

  Future<void> _date({required bool start}) async {
    final now = DateTime.now();
    final initial = (start ? d.from : d.to) ?? d.from ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: start ? DateTime(1975) : (d.from ?? DateTime(1975)),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: SC.field,
            onSurface: SC.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    d.set(() {
      if (start) {
        d.from = picked;
        if (d.to != null && d.to!.isBefore(picked)) d.to = null;
      } else {
        d.to = picked;
      }
    });
  }

  Widget _col(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [FieldLabel(label, required: true), field],
      );

  @override
  Widget build(BuildContext context) {
    final can = d.jobTitle.trim().isNotEmpty &&
        d.company.trim().isNotEmpty &&
        d.department != null &&
        d.industry != null &&
        d.employmentType != null &&
        d.from != null &&
        (d.currentlyWorking || d.to != null);

    return StepScaffold(
      title: 'Add your most recent experience',
      subtitle: 'Tell us about your current or last role.',
      canContinue: can,
      onContinue: widget.onNext,
      children: [
        _col(
          'Job Title',
          SyncTextField(
            controller: _title,
            hint: 'e.g. Product Engineer',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (v) => d.set(() => d.jobTitle = v),
          ),
        ),
        const SizedBox(height: 18),
        _col(
          'Most Recent Company',
          SyncTextField(
            controller: _company,
            hint: 'Company name',
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => d.set(() => d.company = v),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _col(
                'Department',
                SelectField(
                  hint: 'Select department',
                  value: d.department,
                  onTap: () => _select('Department', kDepartments, d.department,
                      (v) => d.department = v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _col(
                'Industry',
                SelectField(
                  hint: 'Select industry',
                  value: d.industry,
                  onTap: () => _select(
                      'Industry', kIndustries, d.industry, (v) => d.industry = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _col(
          'Employment Type',
          SelectField(
            hint: 'Select employment type',
            value: d.employmentType,
            onTap: () => _select('Employment Type', kEmploymentTypes,
                d.employmentType, (v) => d.employmentType = v),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _col(
                'From',
                SelectField(
                  hint: 'dd/mm/yyyy',
                  value: d.from == null ? null : formatDate(d.from!),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _date(start: true),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _col(
                'To',
                SelectField(
                  hint: 'dd/mm/yyyy',
                  value: d.currentlyWorking
                      ? 'Present'
                      : (d.to == null ? null : formatDate(d.to!)),
                  icon: Icons.calendar_today_outlined,
                  onTap: d.currentlyWorking ? null : () => _date(start: false),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => d.set(() => d.currentlyWorking = !d.currentlyWorking),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: d.currentlyWorking ? Colors.white : SC.chip,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: d.currentlyWorking ? Colors.white : const Color(0xFF5A5A60)),
                ),
                child: d.currentlyWorking
                    ? const Icon(Icons.check_rounded, size: 15, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 12),
              Text('I currently work here',
                  style: ST.body.copyWith(fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ],
    );
  }
}
