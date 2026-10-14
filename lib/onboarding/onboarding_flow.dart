import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/options.dart';
import '../models/onboarding_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/curtain_background.dart';
import '../widgets/profile_card.dart';
import 'digilocker_dialog.dart';
import 'steps/experience_step.dart';
import 'steps/resume_step.dart';
import 'steps/search_steps.dart';
import 'steps/simple_steps.dart';

enum Phase { intro, photo, name, role, reveal, steps, done }

enum StepId {
  intent,
  setup,
  resume,
  location,
  level,
  experience,
  roles,
  ctc,
  notice,
  skills,
  links,
  interests,
  gender,
}


/// Onboarding that starts right after phone + email verification.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});

  /// Called after the final step (and the DigiLocker prompt).
  final ValueChanged<OnboardingData>? onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final data = OnboardingData();
  Phase _phase = Phase.intro;
  StepId _step = StepId.intent;
  final List<Timer> _timers = [];
  double _fullH = 0;

  // Card pop-in.
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000));
  // Idle float.
  late final AnimationController _float =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  // Y-axis spin.
  late final AnimationController _spin = AnimationController(vsync: this);
  double _angleFrom = 0, _angleTo = 0;

  // Spring-driven layout motion: retargetable every frame without restarting,
  // so the card never jumps when the keyboard or phase changes.
  final _motion = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  _Spring? _top, _scale, _opacity, _sheet;
  _Pose? _targetPose;
  double _sheetTarget = 0;

  void _onTick(Duration elapsed) {
    final total = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.25);
    _lastTick = elapsed;
    final t = _targetPose;
    if (t == null || _top == null) return;
    // Sub-step so dropped frames keep real-time speed without instability.
    final n = (total * 240).ceil().clamp(1, 60);
    final dt = total / n;
    var moving = false;
    for (var i = 0; i < n; i++) {
      moving |= _top!.step(t.top, dt, 4.6, 0.2);
      moving |= _scale!.step(t.scale, dt, 4.6, 0.0004);
      moving |= _opacity!.step(t.opacity, dt, 6.5, 0.002);
      moving |= _sheet!.step(_sheetTarget, dt, 5.2, 0.2);
    }
    if (moving) _motion.value++;
  }

  double get _angle =>
      lerpDouble(_angleFrom, _angleTo, Curves.easeInOutCubic.transform(_spin.value))!;

  @override
  void initState() {
    super.initState();
    _ticker.start();
    _after(const Duration(milliseconds: 250), _intro.forward);
    _after(const Duration(milliseconds: 2600), () => _setPhase(Phase.photo));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _ticker.dispose();
    _motion.dispose();
    _intro.dispose();
    _float.dispose();
    _spin.dispose();
    data.dispose();
    super.dispose();
  }

  void _after(Duration d, VoidCallback fn) => _timers.add(Timer(d, () {
        if (mounted) fn();
      }));

  // ───────────────────────── card motion ─────────────────────────
  void _spinTo(double target, [Duration d = const Duration(milliseconds: 1150)]) {
    _angleFrom = _angle;
    _angleTo = target;
    _spin.duration = d;
    _spin.forward(from: 0);
  }

  /// Half turn only when the face actually changes; otherwise stay still.
  void _rotateToFace({required bool back, int dir = 1, Duration? d}) {
    if (ProfileCard.isBackAngle(_angleTo) == back) return;
    _spinTo(_angleTo + dir * math.pi, d ?? const Duration(milliseconds: 1150));
  }

  // ───────────────────────── navigation ─────────────────────────
  List<StepId> get _sequence => [
        StepId.intent,
        StepId.setup,
        if (data.usesResume) StepId.resume,
        StepId.location,
        StepId.level,
        if (!data.isFresher) StepId.experience,
        StepId.roles,
        StepId.ctc,
        StepId.notice,
        StepId.skills,
        StepId.links,
        StepId.interests,
        StepId.gender,
      ];

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  void _setPhase(Phase p) {
    _unfocus();
    setState(() => _phase = p);
  }

  void _next() {
    HapticFeedback.mediumImpact();
    switch (_phase) {
      case Phase.photo:
        _setPhase(Phase.name);
      case Phase.name:
        _setPhase(Phase.role);
      case Phase.role:
        _setPhase(Phase.reveal);
        // Front is complete: spin and settle on the back for the rest.
        _spinTo(_angleTo + 3 * math.pi, const Duration(milliseconds: 2100));
        _after(const Duration(milliseconds: 2900), () {
          setState(() {
            _step = StepId.intent;
            _phase = Phase.steps;
          });
        });
      case Phase.steps:
        final seq = _sequence;
        final i = seq.indexOf(_step);
        if (i == seq.length - 1) {
          _finish();
          return;
        }
        _unfocus();
        final next = seq[i + 1];
        setState(() => _step = next);
        _rotateToFace(back: true);
      default:
        break;
    }
  }

  void _back() {
    switch (_phase) {
      case Phase.name:
        _setPhase(Phase.photo);
      case Phase.role:
        _setPhase(Phase.name);
      case Phase.steps:
        final seq = _sequence;
        final i = seq.indexOf(_step);
        if (i <= 0) {
          _setPhase(Phase.role);
          _rotateToFace(back: false, dir: -1);
          return;
        }
        _unfocus();
        final prev = seq[i - 1];
        setState(() => _step = prev);
        _rotateToFace(back: true, dir: -1);
      default:
        break;
    }
  }

  void _finish() {
    _setPhase(Phase.done);
    _rotateToFace(back: true, d: const Duration(milliseconds: 1900));
    _after(const Duration(milliseconds: 2300), _openDigiLocker);
  }

  Future<void> _openDigiLocker() async {
    final ok = await showDigiLockerDialog(context);
    if (ok == true && mounted) {
      data.set(() => data.verified = true);
      widget.onFinished?.call(data);
    }
  }

  Future<void> _pickPhoto(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(
        source: src,
        maxWidth: 900,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.front,
      );
      if (x == null || !mounted) return;
      HapticFeedback.mediumImpact();
      data.set(() => data.photoPath = x.path);
      // Let the photo land on the card, then glide up to the name.
      _after(const Duration(milliseconds: 1300), () {
        if (_phase == Phase.photo) _setPhase(Phase.name);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Could not access your ${src == ImageSource.camera ? 'camera' : 'photos'}'),
      ));
    }
  }

  // ───────────────────────── layout ─────────────────────────
  CardFocus get _focus => switch (_phase) {
        Phase.photo => CardFocus.photo,
        Phase.name => CardFocus.name,
        Phase.role => CardFocus.role,
        Phase.steps => switch (_step) {
            StepId.location => CardFocus.location,
            StepId.level => CardFocus.experience,
            StepId.experience => CardFocus.position,
            StepId.notice => CardFocus.notice,
            _ => CardFocus.none,
          },
        _ => CardFocus.none,
      };

  static const _cardH = ProfileCard.height;
  static const _identityPanelH = 250.0;

  double _stepsStageH(double h, bool kb) =>
      kb ? 0 : (h * 0.32).clamp(150.0, 250.0);

  _Pose _pose(double h, bool kb) {
    final fullH = math.max(_fullH, h);
    switch (_phase) {
      case Phase.intro:
      case Phase.reveal:
      case Phase.done:
        final s = math.min(1.0, (h - 200) / _cardH).clamp(0.4, 1.0);
        return _Pose((h - 170 - _cardH * s) / 2, s, 1);
      case Phase.photo:
      case Phase.name:
      case Phase.role:
        final s = ((fullH - _identityPanelH - 20) / _cardH).clamp(0.45, 0.95);
        final photoTop = math.max(8.0, (fullH - _identityPanelH - _cardH * s) / 2);
        if (_phase == Phase.photo) return _Pose(photoTop, s, 1);
        final panelTop = h - (_phase == Phase.role ? 290 : 245);
        if (_phase == Phase.name) {
          // Slide up so the name line sits just above the input.
          return _Pose(
              math.min(photoTop - 0.22 * _cardH * s, panelTop - 0.70 * _cardH * s), s, 1);
        }
        // A little further up for the dream role.
        return _Pose(
            math.min(photoTop - 0.30 * _cardH * s, panelTop - 0.80 * _cardH * s), s, 1);
      case Phase.steps:
        final stage = _stepsStageH(h, kb);
        if (kb) return _Pose(-_cardH * 0.5 - 40, 0.5, 0);
        final s = ((stage - 22) / _cardH).clamp(0.25, 0.62);
        return _Pose((stage - _cardH * s) / 2 + 4, s, 1);
    }
  }

  int get _progressIndex => switch (_phase) {
        Phase.intro => 0,
        Phase.photo => 0,
        Phase.name => 1,
        Phase.role => 2,
        Phase.reveal => 3,
        Phase.steps => 3 + _sequence.indexOf(_step),
        Phase.done => 3 + _sequence.length,
      };

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: SC.bg,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const Positioned.fill(child: CurtainBackground()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _topBar(),
                  Expanded(
                    child: LayoutBuilder(builder: (context, c) {
                      if (!kb) _fullH = c.maxHeight;
                      return _stage(c.maxWidth, c.maxHeight, kb);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    final canBack = _phase == Phase.name ||
        _phase == Phase.role ||
        _phase == Phase.steps;
    final total = 3 + _sequence.length;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _phase == Phase.intro ? 0 : 1,
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 8,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: canBack ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !canBack,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _back,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_back_rounded,
                                  size: 16, color: SC.textDim),
                              const SizedBox(width: 6),
                              Text('Back',
                                  style: ST.small.copyWith(fontSize: 14.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SyncUpLogo(size: 30),
                Positioned(
                  right: 6,
                  child: IconButton(
                    onPressed: _showAssistance,
                    icon: const Icon(Icons.help_outline_rounded,
                        size: 20, color: SC.textDim),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (_progressIndex / total).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 2,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage(double w, double h, bool kb) {
    final steps = _phase == Phase.steps;
    final stageH = _stepsStageH(h, kb);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    // Update spring targets (read by the ticker; no rebuild needed).
    final target = _pose(h, kb);
    _targetPose = target;
    _sheetTarget = steps ? stageH : h + 20;
    _top ??= _Spring(target.top);
    _scale ??= _Spring(target.scale);
    _opacity ??= _Spring(target.opacity);
    _sheet ??= _Spring(h + 20);

    return Stack(
      children: [
        // ── Card ──
        Positioned.fill(
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _motion,
              child: _animatedCard(),
              builder: (_, child) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: _top!.x,
                    left: (w - ProfileCard.width) / 2,
                    child: Opacity(
                      opacity: _opacity!.x.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: _scale!.x,
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Identity / caption panel ──
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            ignoring: steps,
            child: AnimatedSlide(
              offset: steps ? const Offset(0, 0.4) : Offset.zero,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: steps ? 0 : 1,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00050506), Color(0xF2050506), SC.bg],
                      stops: [0, 0.18, 1],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                      22, 36, 22, (kb ? 12 : safeBottom) + 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 550),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                                begin: const Offset(0, 0.12), end: Offset.zero)
                            .animate(a),
                        child: child,
                      ),
                    ),
                    layoutBuilder: (cur, prev) => Stack(
                      alignment: Alignment.bottomCenter,
                      children: [...prev, ?cur],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_phase),
                      child: _identityPanel(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Steps sheet ──
        Positioned(
          left: 0,
          right: 0,
          top: stageH,
          bottom: 0,
          child: AnimatedBuilder(
            animation: _motion,
            child: _stepsSheet(),
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _sheet!.x - stageH),
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _animatedCard() => AnimatedBuilder(
        animation: Listenable.merge([_intro, _float, _spin, data]),
        builder: (_, _) {
          final it = _intro.value;
          final e = Curves.easeInOutCubic.transform(it);
          final popOpacity = Curves.easeOut.transform((it / 0.5).clamp(0.0, 1.0));
          final popScale = 0.82 + 0.18 * e;
          final popDy = 120 * (1 - e);
          final popTilt = 0.7 * (1 - e);

          final f = _float.value * 2 * math.pi;
          return Transform.translate(
            offset: Offset(0, popDy + math.sin(f) * 5),
            child: Opacity(
              opacity: popOpacity,
              child: Transform.scale(
                scale: popScale,
                child: ProfileCard(
                  data: data,
                  angle: _angle + math.cos(f) * 0.02,
                  tiltX: popTilt + math.sin(f) * 0.015,
                  focus: _focus,
                ),
              ),
            ),
          );
        },
      );

  // ───────────────────────── identity panels ─────────────────────────
  Widget _identityPanel() {
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) => switch (_phase) {
        Phase.intro => _caption(
            'Your SyncUp card',
            'Complete your profile to unlock verified talent matching and telemetry access.',
            delay: 900,
          ),
        Phase.photo => _photoPanel(),
        Phase.name => _NamePanel(data: data, onNext: _next),
        Phase.role => _RolePanel(data: data, onNext: _next),
        Phase.reveal => _caption(
            data.firstName.isEmpty
                ? 'Looking sharp.'
                : 'Looking sharp, ${data.firstName}.',
            "Your card is ready. Let's complete the rest of your profile.",
          ),
        Phase.done => _donePanel(),
        Phase.steps => const SizedBox(height: 120),
      },
    );
  }

  Widget _caption(String title, String sub, {int delay = 0}) => Reveal(
        delay: Duration(milliseconds: delay),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, textAlign: TextAlign.center, style: ST.h1),
              const SizedBox(height: 10),
              Text(sub, textAlign: TextAlign.center, style: ST.sub),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  Widget _photoPanel() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add your photo', style: ST.h1),
          const SizedBox(height: 8),
          Text('A clear, professional photo builds trust with recruiters.',
              style: ST.sub),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SourceTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: () => _pickPhoto(ImageSource.camera),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(child: FooterTextButton('Skip for now', onTap: _next)),
              const Spacer(),
              SyncButton(
                label: 'Continue',
                enabled: data.photoPath != null,
                onPressed: _next,
              ),
            ],
          ),
        ],
      );

  Widget _donePanel() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.firstName.isEmpty
                ? "You're all set."
                : "You're all set, ${data.firstName}.",
            textAlign: TextAlign.center,
            style: ST.h1,
          ),
          const SizedBox(height: 10),
          Text(
            data.verified
                ? 'Identity verified. Your card now carries the verified badge.'
                : 'Your profile is complete. Verify your identity to earn the verified badge.',
            textAlign: TextAlign.center,
            style: ST.sub,
          ),
          const SizedBox(height: 20),
          SyncButton(
            label: data.verified ? 'Go to dashboard' : 'Verify identity',
            icon: data.verified ? Icons.arrow_forward_rounded : Icons.verified_user_outlined,
            expand: true,
            onPressed: data.verified
                ? () => widget.onFinished?.call(data)
                : _openDigiLocker,
          ),
        ],
      );

  // ───────────────────────── steps ─────────────────────────
  Widget _stepsSheet() => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xF50A0A0C),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: ListenableBuilder(
              listenable: data,
              builder: (context, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 480),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                        .animate(a),
                    child: child,
                  ),
                ),
                layoutBuilder: (cur, prev) => Stack(
                  fit: StackFit.expand,
                  children: [...prev, ?cur],
                ),
                child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
              ),
            ),
          ),
        ),
      );

  Widget _buildStep() {
    final d = data;
    switch (_step) {
      case StepId.intent:
        return SingleChoiceStep(
          title: 'What brings you here?',
          subtitle: 'Choose one so we can tailor SyncUp to what you need.',
          options: kIntents,
          value: d.intent,
          onSelect: (v) => d.set(() => d.intent = v),
          onNext: _next,
        );
      case StepId.setup:
        return SingleChoiceStep(
          title: 'How would you like to set up your profile?',
          subtitle: 'Choose how you want to provide your professional details.',
          options: kSetupModes,
          value: d.setupMode,
          onSelect: (v) => d.set(() => d.setupMode = v),
          onNext: _next,
        );
      case StepId.resume:
        return ResumeStep(
          data: d,
          onNext: _next,
          onParsed: () {},
        );
      case StepId.location:
        return LocationStep(data: d, onNext: _next);
      case StepId.level:
        return SingleChoiceStep(
          title: 'Tell us about yourself',
          subtitle: 'Select the option that best describes your current experience level.',
          options: kLevels,
          value: d.level,
          onSelect: (v) => d.set(() => d.level = v),
          onNext: _next,
        );
      case StepId.experience:
        return ExperienceStep(data: d, onNext: _next);
      case StepId.roles:
        return RolesStep(data: d, onNext: _next);
      case StepId.ctc:
        return CtcStep(data: d, onNext: _next);
      case StepId.notice:
        return SingleChoiceStep(
          title: 'What is your notice period?',
          subtitle: 'Choose when you can join a new role.',
          options: kNoticePeriods,
          value: d.notice,
          onSelect: (v) => d.set(() => d.notice = v),
          onNext: _next,
        );
      case StepId.skills:
        return SkillsStep(data: d, onNext: _next);
      case StepId.links:
        return LinksStep(data: d, onNext: _next);
      case StepId.interests:
        return InterestsStep(data: d, onNext: _next);
      case StepId.gender:
        return SingleChoiceStep(
          title: "What's your gender?",
          subtitle: 'Please select your gender to help us personalize your experience.',
          options: kGenders,
          value: d.gender,
          onSelect: (v) => d.set(() => d.gender = v),
          onNext: _next,
        );
    }
  }

  // ───────────────────────── assistance ─────────────────────────
  void _showAssistance() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 26, 24, MediaQuery.viewPaddingOf(context).bottom + 24),
        decoration: BoxDecoration(
          color: SC.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SyncUpLogo(size: 34),
            const SizedBox(height: 18),
            Text(
              'Complete your profile to unlock verified talent matching and telemetry access.',
              style: ST.sub.copyWith(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 22),
            Container(height: 1, color: SC.border),
            const SizedBox(height: 22),
            Row(
              children: [
                const Icon(Icons.help_outline_rounded, size: 16, color: SC.text),
                const SizedBox(width: 8),
                Text('Need Assistance?', style: ST.label),
              ],
            ),
            const SizedBox(height: 10),
            Text('Contact our engineering onboarding desk:', style: ST.small),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.mail_outline_rounded, size: 15, color: SC.textDim),
                const SizedBox(width: 8),
                Text('support@syncup.ai', style: ST.mono.copyWith(color: SC.text)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.logout_rounded, size: 15, color: SC.textDim),
                const SizedBox(width: 8),
                Text('Logout', style: ST.mono.copyWith(color: SC.text)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── identity sub-panels ─────────────────────────
class _NamePanel extends StatefulWidget {
  const _NamePanel({required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<_NamePanel> createState() => _NamePanelState();
}

class _NamePanelState extends State<_NamePanel> {
  late final _c = TextEditingController(text: widget.data.name);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _valid => widget.data.name.trim().length >= 2;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your name?", style: ST.h1),
          const SizedBox(height: 8),
          Text("This is how you'll appear on your SyncUp card.", style: ST.sub),
          const SizedBox(height: 18),
          SyncTextField(
            controller: _c,
            hint: 'Full name',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_outline_rounded,
            onChanged: (v) => widget.data.set(() => widget.data.name = v),
            onSubmitted: (_) {
              if (_valid) widget.onNext();
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SyncButton(
                label: 'Continue', enabled: _valid, onPressed: widget.onNext),
          ),
        ],
      );
}

class _RolePanel extends StatefulWidget {
  const _RolePanel({required this.data, required this.onNext});
  final OnboardingData data;
  final VoidCallback onNext;

  @override
  State<_RolePanel> createState() => _RolePanelState();
}

class _RolePanelState extends State<_RolePanel> {
  late final _c = TextEditingController(text: widget.data.dreamRole);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _valid => widget.data.dreamRole.trim().length >= 2;

  void _set(String v) => widget.data.set(() => widget.data.dreamRole = v);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's your dream role?", style: ST.h1),
          const SizedBox(height: 8),
          Text("The role you're working towards — it headlines your card.",
              style: ST.sub),
          const SizedBox(height: 18),
          SyncTextField(
            controller: _c,
            hint: 'e.g. Software Engineer',
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.auto_awesome_outlined,
            onChanged: _set,
            onSubmitted: (_) {
              if (_valid) widget.onNext();
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kDreamRoleSuggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final r = kDreamRoleSuggestions[i];
                final on = widget.data.dreamRole == r;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _c.text = r;
                    _set(r);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : SC.chip,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: on ? Colors.white : SC.border),
                    ),
                    child: Text(r,
                        style: ST.body.copyWith(
                            fontSize: 13, color: on ? Colors.black : SC.text)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SyncButton(
                label: 'Create my card', enabled: _valid, onPressed: widget.onNext),
          ),
        ],
      );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: SC.field,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SC.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Text(label, style: ST.body.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// ───────────────────────── pose ─────────────────────────
@immutable
class _Pose {
  const _Pose(this.top, this.scale, this.opacity);
  final double top, scale, opacity;
}

/// Critically damped spring: starts gently, never overshoots, retargetable.
class _Spring {
  _Spring(this.x);
  double x;
  double v = 0;

  /// Returns true while still moving.
  bool step(double target, double dt, double w, double eps) {
    final a = w * w * (target - x) - 2 * w * v;
    v += a * dt;
    x += v * dt;
    if ((target - x).abs() < eps && v.abs() < eps) {
      final moved = x != target;
      x = target;
      v = 0;
      return moved;
    }
    return true;
  }
}
