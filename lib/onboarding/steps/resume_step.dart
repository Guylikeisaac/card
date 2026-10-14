import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/onboarding_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Upload → animated parsing → parsed summary.
class ResumeStep extends StatefulWidget {
  const ResumeStep({
    super.key,
    required this.data,
    required this.onNext,
    required this.onParsed,
  });
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onParsed;

  @override
  State<ResumeStep> createState() => _ResumeStepState();
}

enum _Stage { idle, parsing, done }

class _ResumeStepState extends State<ResumeStep>
    with SingleTickerProviderStateMixin {
  static const _tasks = [
    'Reading document',
    'Extracting experience',
    'Detecting skills',
    'Mapping education',
  ];

  late _Stage _stage = widget.data.resumeParsed ? _Stage.done : _Stage.idle;
  int _tick = 0;
  Timer? _timer;
  late final AnimationController _scan = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _timer?.cancel();
    _scan.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final f = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'doc', 'docx'],
      );
      if (f == null || !mounted) return;
      widget.data.set(() {
        widget.data.resumeName = f.name;
        widget.data.resumeParsed = false;
      });
      _startParsing();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open files')));
    }
  }

  void _startParsing() {
    setState(() {
      _stage = _Stage.parsing;
      _tick = 0;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return t.cancel();
      setState(() => _tick++);
      if (_tick >= _tasks.length) {
        t.cancel();
        _applyParsed();
        setState(() => _stage = _Stage.done);
        widget.onParsed();
      }
    });
  }

  /// Frontend-only: replace with the response from the resume parser API.
  void _applyParsed() {
    final d = widget.data;
    d.set(() {
      d.resumeParsed = true;
      d.location ??= 'Bengaluru, Karnataka';
      d.level ??= 'Experienced Professional';
      if (d.jobTitle.isEmpty) d.jobTitle = 'Product Engineer';
      if (d.company.isEmpty) d.company = 'Inditech Technologies';
      d.department ??= 'Engineering - Software & QA';
      d.industry ??= 'IT Services & Consulting';
      d.employmentType ??= 'Full-time';
      if (d.from == null) {
        d.from = DateTime(2022, 7, 1);
        d.currentlyWorking = true;
      }
      if (d.skills.isEmpty) d.skills.addAll(['Python', 'JavaScript', 'Figma']);
      if (d.roles.isEmpty) d.roles.add('Software Engineer');
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final (title, sub) = switch (_stage) {
      _Stage.idle => (
          'Upload your resume',
          "PDF or DOCX up to 5 MB. We'll auto-fill your experience, skills, and education."
        ),
      _Stage.parsing => (
          'Reading your resume',
          'Hang tight — this only takes a few seconds.'
        ),
      _Stage.done => (
          'Your resume is parsed',
          'We pre-filled your profile. Review and edit each detail in the next steps.'
        ),
    };

    return StepScaffold(
      key: ValueKey(_stage),
      title: title,
      subtitle: sub,
      canContinue: _stage == _Stage.done,
      onContinue: widget.onNext,
      footerLeft: _stage == _Stage.done
          ? FooterTextButton('Replace file', onTap: _pick)
          : null,
      children: switch (_stage) {
        _Stage.idle => [_dropzone()],
        _Stage.parsing => [_fileRow(d.resumeName ?? 'resume.pdf', false), _parsing()],
        _Stage.done => [_fileRow(d.resumeName ?? 'resume.pdf', true), _summary(d)],
      },
    );
  }

  Widget _dropzone() => GestureDetector(
        onTap: _pick,
        child: CustomPaint(
          painter: _DashedBorder(),
          child: Container(
            height: 200,
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SC.chip,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: const Icon(Icons.file_upload_outlined, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text('Tap to upload resume', style: ST.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('PDF, DOC, DOCX · Max 5 MB', style: ST.small),
              ],
            ),
          ),
        ),
      );

  Widget _fileRow(String name, bool done) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SC.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: done ? SC.borderHi : SC.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ST.body.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (done) const RadioMark(selected: true, size: 20),
          ],
        ),
      );

  Widget _parsing() => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document with scanning line.
            Container(
              width: 104,
              height: 136,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFF161618),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SC.border),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final w in [0.6, 0.9, 0.75, 0.0, 0.85, 0.5, 0.95, 0.7])
                          w == 0
                              ? const SizedBox(height: 8)
                              : Container(
                                  margin: const EdgeInsets.only(bottom: 7),
                                  height: 5,
                                  width: 80 * w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _scan,
                    builder: (_, _) => Positioned(
                      top: -20 + 156 * Curves.easeInOut.transform(_scan.value),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _tasks.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: i < _tick
                                ? const RadioMark(selected: true, size: 20)
                                : i == _tick
                                    ? const Padding(
                                        padding: EdgeInsets.all(2),
                                        child: CircularProgressIndicator(
                                            strokeWidth: 1.6, color: Colors.white),
                                      )
                                    : const RadioMark(selected: false, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: ST.body.copyWith(
                                fontSize: 14,
                                color: i <= _tick ? SC.text : SC.textFaint,
                              ),
                              child: Text(_tasks[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: _tick / _tasks.length),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 3,
                        color: Colors.white,
                        backgroundColor: SC.border,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _summary(OnboardingData d) {
    final rows = [
      (Icons.work_outline_rounded, 'Experience', '${d.jobTitle} · ${d.company}'),
      (Icons.location_on_outlined, 'Location', d.location ?? '—'),
      (Icons.bolt_outlined, 'Skills', d.skills.join(', ')),
      (Icons.search_rounded, 'Open to', d.roles.join(', ')),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: SC.field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SC.border),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(r.$1, size: 19, color: SC.textDim),
                  const SizedBox(width: 12),
                  SizedBox(width: 78, child: Text(r.$2, style: ST.small)),
                  Expanded(
                    child: Text(r.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ST.body.copyWith(fontSize: 14)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        Offset.zero & size, const Radius.circular(16));
    canvas.drawRRect(rrect, Paint()..color = SC.field);
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = const Color(0xFF4A4A50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < m.length) {
        canvas.drawPath(m.extractPath(dist, dist + 7), paint);
        dist += 13;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
