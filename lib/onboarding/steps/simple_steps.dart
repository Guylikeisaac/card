import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/options.dart';
import '../../models/onboarding_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Radio-list step (intent, setup, level, notice, gender).
class SingleChoiceStep extends StatelessWidget {
  const SingleChoiceStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.value,
    required this.onSelect,
    required this.onNext,
  });
  final String title;
  final String subtitle;
  final List<ChoiceOption> options;
  final String? value;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => StepScaffold(
        title: title,
        subtitle: subtitle,
        canContinue: value != null,
        onContinue: onNext,
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OptionTile(
                title: o.title,
                description: o.description,
                icon: o.icon,
                selected: value == o.title,
                onTap: () => onSelect(o.title),
              ),
            ),
        ],
      );
}

// ───────────────────────── Roles ─────────────────────────
class RolesStep extends StatelessWidget {
  const RolesStep({super.key, required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final n = data.roles.length;
    return StepScaffold(
      title: 'What kind of role are you open to?',
      subtitle: 'Search for a role or type your own job title if it is not listed.',
      canContinue: n > 0,
      onContinue: onNext,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: n == 0
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final r in data.roles)
                        TagChip(
                          key: ValueKey(r),
                          label: r,
                          onRemove: () => data.set(() => data.roles.remove(r)),
                        ),
                    ],
                  ),
                ),
        ),
        SelectField(
          hint: n >= 5 ? 'Maximum 5 roles added' : 'Add job role ($n/5)',
          hintBright: true,
          onTap: n >= 5
              ? null
              : () async {
                  final r = await showPickerSheet(
                    context,
                    title: 'Add job role',
                    options: kRoles,
                    searchable: true,
                    allowCustom: true,
                    exclude: data.roles.toSet(),
                  );
                  if (r != null && !data.roles.contains(r) && data.roles.length < 5) {
                    data.set(() => data.roles.add(r));
                  }
                },
        ),
      ],
    );
  }
}

// ───────────────────────── CTC ─────────────────────────
class CtcStep extends StatefulWidget {
  const CtcStep({super.key, required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<CtcStep> createState() => _CtcStepState();
}

class _CtcStepState extends State<CtcStep> {
  late final _cur = TextEditingController(text: widget.data.currentCtc);
  late final _exp = TextEditingController(text: widget.data.expectedCtc);
  final _fmt = [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?'))];

  @override
  void dispose() {
    _cur.dispose();
    _exp.dispose();
    super.dispose();
  }

  Widget _rupee() => Padding(
        padding: const EdgeInsets.only(left: 18, right: 8),
        child: Text('₹', style: ST.body.copyWith(color: SC.textDim)),
      );

  Widget _lpa() => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text('LPA', style: ST.small.copyWith(color: SC.textFaint)),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    bool ok(String s) => double.tryParse(s) != null;
    return StepScaffold(
      title: 'What is your current and expected CTC?',
      subtitle:
          'Enter amounts in lakhs per annum (INR). Numbers and decimals allowed — e.g. 10.5 for ₹10.5 LPA.',
      canContinue: ok(d.currentCtc) && ok(d.expectedCtc),
      onContinue: widget.onNext,
      footerLeft: FooterTextButton('Skip', onTap: widget.onNext),
      children: [
        const FieldLabel('Current CTC (LPA)'),
        SyncTextField(
          controller: _cur,
          hint: 'e.g. 10.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _fmt,
          prefix: _rupee(),
          suffix: _lpa(),
          textInputAction: TextInputAction.next,
          onChanged: (v) => d.set(() => d.currentCtc = v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 22),
          child: Text(
              'Example: 10.5 means current CTC is 10.5 lakhs per annum (INR).',
              style: ST.small),
        ),
        const FieldLabel('Expected CTC (LPA)'),
        SyncTextField(
          controller: _exp,
          hint: 'e.g. 12.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _fmt,
          prefix: _rupee(),
          suffix: _lpa(),
          onChanged: (v) => d.set(() => d.expectedCtc = v),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
              'Example: 12.5 means expected CTC is 12.5 lakhs per annum (INR).',
              style: ST.small),
        ),
      ],
    );
  }
}

// ───────────────────────── Interests ─────────────────────────
class InterestsStep extends StatelessWidget {
  const InterestsStep({super.key, required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final n = data.interests.length;
    return StepScaffold(
      title: 'Discover what drives you',
      badge: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: n == 0
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(n),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('$n selected',
                        style: ST.label.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
      ),
      subtitle:
          'Select at least three interests to personalize your experience and recommendations.',
      canContinue: n >= 3,
      onContinue: onNext,
      footerLeft: Text(
        n >= 3 ? 'Ready to continue' : 'Select ${3 - n} more',
        style: ST.small.copyWith(fontSize: 14),
      ),
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.98,
          children: [
            for (final it in kInterests)
              _InterestTile(
                interest: it,
                selected: data.interests.contains(it.label),
                onTap: () => data.set(() {
                  if (!data.interests.remove(it.label)) {
                    data.interests.add(it.label);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }
}

class _InterestTile extends StatefulWidget {
  const _InterestTile(
      {required this.interest, required this.selected, required this.onTap});
  final Interest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_InterestTile> createState() => _InterestTileState();
}

class _InterestTileState extends State<_InterestTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.selected;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          decoration: BoxDecoration(
            color: s ? SC.fieldHi : SC.field,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: s ? SC.borderHi : SC.border, width: s ? 1.4 : 1),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedScale(
                  scale: s ? 1 : 0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: const RadioMark(selected: true, size: 18),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s ? Colors.white : SC.chip,
                        ),
                        child: Icon(widget.interest.icon,
                            size: 18, color: s ? Colors.black : SC.textDim),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.interest.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: ST.body.copyWith(
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: s ? FontWeight.w600 : FontWeight.w500,
                          color: s ? SC.text : const Color(0xFFD0D0D4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
