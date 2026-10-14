import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/options.dart';
import '../../models/onboarding_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

Widget _listRow(String label,
    {required VoidCallback onTap, bool highlighted = false, IconData? icon}) {
  return Material(
    color: highlighted ? SC.fieldHi : Colors.transparent,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      highlightColor: Colors.white.withValues(alpha: 0.06),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(label,
                  style: ST.body.copyWith(
                      fontWeight: highlighted ? FontWeight.w500 : FontWeight.w400,
                      color: highlighted ? SC.text : const Color(0xFFD6D6DA))),
            ),
          ],
        ),
      ),
    ),
  );
}

// ───────────────────────── Location ─────────────────────────
class LocationStep extends StatefulWidget {
  const LocationStep({super.key, required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  late final _c = TextEditingController(text: widget.data.location ?? '');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _pick(String city) {
    _c.text = city;
    widget.data.set(() => widget.data.location = city);
    _focus.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final text = _c.text.trim();
    final q = (d.location != null && text == d.location) ? '' : text.toLowerCase();
    final list = kCities.where((c) => c.toLowerCase().contains(q)).toList();

    return StepScaffold(
      title: 'Where are you based?',
      subtitle: 'Tell us where you are located and your preferred work destinations.',
      canContinue: d.location != null,
      onContinue: widget.onNext,
      children: [
        const FieldLabel('Current Location', required: true),
        SyncTextField(
          controller: _c,
          focusNode: _focus,
          hint: "Search city or type 'Remote'...",
          prefixIcon: Icons.location_on_outlined,
          suffix: d.location != null
              ? const Icon(Icons.check_circle_rounded, size: 19, color: Colors.white)
              : null,
          onChanged: (v) {
            setState(() {});
            if (d.location != null && v.trim() != d.location) {
              d.set(() => d.location = null);
            }
          },
          onSubmitted: (v) {
            if (list.isNotEmpty) {
              _pick(list.first);
            } else if (v.trim().isNotEmpty) {
              _pick(v.trim());
            }
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_focus.hasFocus
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 290),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: SC.field,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: SC.border),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      for (var i = 0; i < list.length; i++)
                        _listRow(list[i],
                            highlighted: i == 0, onTap: () => _pick(list[i])),
                      if (list.isEmpty && text.isNotEmpty)
                        _listRow('Use "$text"',
                            icon: Icons.add_rounded, onTap: () => _pick(text)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ───────────────────────── Skills ─────────────────────────
class SkillsStep extends StatefulWidget {
  const SkillsStep({super.key, required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _add(String s) {
    final d = widget.data;
    if (d.skills.length >= 5 || d.skills.contains(s)) return;
    d.set(() => d.skills.add(s));
    _q.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final q = _q.text.trim();
    final full = d.skills.length >= 5;
    final list = kSkills
        .where((s) =>
            !d.skills.contains(s) && s.toLowerCase().contains(q.toLowerCase()))
        .take(8)
        .toList();
    final custom = q.isNotEmpty &&
        !kSkills.any((s) => s.toLowerCase() == q.toLowerCase()) &&
        !d.skills.any((s) => s.toLowerCase() == q.toLowerCase());

    return StepScaffold(
      title: 'Write your top 5 skills',
      subtitle: 'Search and select the skills that best represent your expertise.',
      canContinue: d.skills.isNotEmpty,
      onContinue: widget.onNext,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: d.skills.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in d.skills)
                        TagChip(
                          key: ValueKey(s),
                          label: s,
                          onRemove: () => d.set(() => d.skills.remove(s)),
                        ),
                    ],
                  ),
                ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SC.field,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SC.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: SyncTextField(
                  controller: _q,
                  hint: full ? 'You have added 5 skills' : 'Search skills',
                  prefixIcon: Icons.search_rounded,
                  fill: const Color(0xFF1A1A1D),
                  radius: 10,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) {
                    if (custom) {
                      _add(q);
                    } else if (list.isNotEmpty) {
                      _add(list.first);
                    }
                  },
                ),
              ),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: full ? 0.35 : 1,
                child: IgnorePointer(
                  ignoring: full,
                  child: Column(
                    children: [
                      if (custom)
                        _listRow('Add "$q"',
                            icon: Icons.add_rounded, onTap: () => _add(q)),
                      for (final s in list) _listRow(s, onTap: () => _add(s)),
                      if (list.isEmpty && !custom)
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text('No matching skills', style: ST.small),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Links ─────────────────────────
class LinksStep extends StatefulWidget {
  const LinksStep({super.key, required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<LinksStep> createState() => _LinksStepState();
}

class _LinksStepState extends State<LinksStep> {
  final _c = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _add() {
    var raw = _c.text.trim();
    if (raw.isEmpty) return;
    if (!raw.startsWith(RegExp(r'https?://'))) raw = 'https://$raw';
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.host.contains('.')) {
      setState(() => _error = 'Enter a valid URL');
      return;
    }
    final d = widget.data;
    if (d.links.any((l) => l.url == raw)) {
      setState(() => _error = 'This link is already added');
      return;
    }
    d.set(() => d.links.add(WorkLink(raw)));
    _c.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasText = _c.text.trim().isNotEmpty;
    return StepScaffold(
      title: 'Add your work links',
      subtitle: 'Share profiles where recruiters can review your work.',
      canContinue: d.links.isNotEmpty,
      onContinue: widget.onNext,
      footerLeft: d.links.isEmpty
          ? FooterTextButton('Skip', onTap: widget.onNext)
          : null,
      children: [
        Row(
          children: [
            Expanded(
              child: SyncTextField(
                controller: _c,
                hint: 'Paste GitHub, LinkedIn, Portfolio, Figma, or any URL',
                prefixIcon: Icons.link_rounded,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: hasText ? _add : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: hasText ? Colors.white : SC.field,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: hasText ? Colors.white : SC.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_rounded,
                        size: 16, color: hasText ? Colors.black : SC.textDim),
                    const SizedBox(width: 4),
                    Text(
                      'ADD LINK',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: hasText ? Colors.black : SC.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(_error!, style: ST.small.copyWith(color: Colors.white)),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Row(
            children: [
              Text(
                'ADDED LINKS (${d.links.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: SC.text,
                ),
              ),
              const Spacer(),
              Text('Showcased on your profile',
                  style: ST.small.copyWith(fontSize: 12)),
            ],
          ),
        ),
        Column(
          children: [
            if (d.links.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SC.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.link_off_rounded, color: SC.textFaint),
                    const SizedBox(height: 8),
                    Text('No links added yet', style: ST.small),
                  ],
                ),
              ),
            for (final l in d.links)
              _LinkRow(
                key: ValueKey(l.url),
                link: l,
                onDelete: () => d.set(() => d.links.remove(l)),
              ),
          ],
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({super.key, required this.link, required this.onDelete});
  final WorkLink link;
  final VoidCallback onDelete;

  Widget _glyph() {
    switch (link.kind) {
      case LinkKind.linkedin:
        return Text('in',
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white));
      case LinkKind.behance:
        return Text('Bē',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white));
      case LinkKind.github:
        return const Icon(Icons.code_rounded, size: 18, color: Colors.white);
      case LinkKind.figma:
        return const Icon(Icons.design_services_outlined, size: 17, color: Colors.white);
      case LinkKind.dribbble:
        return const Icon(Icons.sports_basketball_outlined,
            size: 17, color: Colors.white);
      case LinkKind.web:
        return const Icon(Icons.public_rounded, size: 18, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          decoration: BoxDecoration(
            color: SC.field,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: SC.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SC.chip,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Center(child: _glyph()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(link.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ST.body.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(link.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ST.mono.copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 19, color: SC.textDim),
              ),
            ],
          ),
        ),
      );
}
