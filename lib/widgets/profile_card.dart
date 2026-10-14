import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/onboarding_data.dart';

enum CardFocus { none, photo, name, role, experience, position, notice, location }

/// The premium glass SyncUp identity card. Front: photo, name, dream role.
/// Back: experience, position, notice period, location.
class ProfileCard extends StatefulWidget {
  const ProfileCard({
    super.key,
    required this.data,
    this.angle = 0,
    this.tiltX = 0,
    this.focus = CardFocus.none,
  });

  static const width = 260.0;
  static const height = 380.0;

  final OnboardingData data;

  /// Y-axis rotation in radians. Back face shows between pi/2 and 3pi/2.
  final double angle;
  final double tiltX;
  final CardFocus focus;

  static bool isBackAngle(double a) {
    final n = a % (2 * math.pi);
    return n > math.pi / 2 && n < 3 * math.pi / 2;
  }

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with TickerProviderStateMixin {
  late final AnimationController _sheen =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))
        ..repeat();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final back = ProfileCard.isBackAngle(widget.angle);
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0011)
      ..rotateX(widget.tiltX)
      ..rotateY(widget.angle);

    Widget face = back
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: _shell(_back()),
          )
        : _shell(_front());

    return Transform(
      alignment: Alignment.center,
      transform: m,
      child: SizedBox(
        width: ProfileCard.width,
        height: ProfileCard.height,
        child: face,
      ),
    );
  }

  // ───────────────────────── glass shell ─────────────────────────
  Widget _shell(Widget content) {
    const r = 30.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Slab thickness.
        Positioned(
          left: 5,
          top: 5,
          right: -5,
          bottom: -5,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4A4A50), Color(0xFF1A1A1D), Color(0xFF2C2C30)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 60,
                  offset: const Offset(0, 34),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 40,
                ),
              ],
            ),
          ),
        ),
        // Face.
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D2D31), Color(0xFF141416), Color(0xFF0A0A0B)],
                  stops: [0, 0.45, 1],
                ),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24), width: 1.2),
              ),
              child: Stack(
                children: [
                  // Glass reflection.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: const Alignment(0.2, 0.1),
                            colors: [
                              Colors.white.withValues(alpha: 0.10),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Inner bevel line.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(r - 5),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                    ),
                  ),
                  // Moving sheen.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _sheen,
                        builder: (_, _) {
                          final v = _sheen.value;
                          // Sweep during the first 40% of the cycle, then rest.
                          final p = (v / 0.4).clamp(0.0, 1.0);
                          final dx = -1.6 + 3.2 * Curves.easeInOut.transform(p);
                          return Transform.translate(
                            offset: Offset(dx * ProfileCard.width, 0),
                            child: Transform.rotate(
                              angle: 0.35,
                              child: Center(
                                child: Container(
                                  width: 70,
                                  height: ProfileCard.height * 1.6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.07),
                                      Colors.transparent,
                                    ]),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(child: content),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── front ─────────────────────────
  Widget _front() {
    final d = widget.data;
    final f = widget.focus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 22),
      child: Column(
        children: [
          _photo(d, f == CardFocus.photo),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: d.name.trim().isEmpty
                        ? Colors.white.withValues(alpha: 0.28)
                        : Colors.white,
                  ),
                  child: Text(
                    d.name.trim().isEmpty ? 'Your Name' : d.name.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (d.verified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
              ],
            ],
          ),
          _focusLine(f == CardFocus.name),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: d.dreamRole.trim().isEmpty
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.72),
            ),
            child: Text(
              d.dreamRole.trim().isEmpty ? 'Dream Role' : d.dreamRole.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _focusLine(f == CardFocus.role),
          const SizedBox(height: 16),
          _wordmark(),
        ],
      ),
    );
  }

  Widget _focusLine(bool on) => AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(top: 4),
          width: on ? 46 : 0,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withValues(
                alpha: 0.35 + 0.5 * math.sin(_pulse.value * math.pi)),
          ),
        ),
      );

  Widget _wordmark() => Text(
        'SyncUp',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      );

  Widget _photo(OnboardingData d, bool focused) {
    const size = 150.0;
    final hasPhoto = d.photoPath != null;
    return SizedBox(
      width: size + 30,
      height: size + 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (focused && !hasPhoto)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final v = _pulse.value;
                return Container(
                  width: size + 26 * v,
                  height: size + 26 * v,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45 * (1 - v)),
                      width: 1.4,
                    ),
                  ),
                );
              },
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4A4A4F), Color(0xFF1A1A1C)],
              ),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween(begin: 1.25, end: 1.0).animate(a),
                    child: child,
                  ),
                ),
                child: hasPhoto
                    ? Image(
                        image: kIsWeb
                            ? NetworkImage(d.photoPath!)
                            : FileImage(File(d.photoPath!)) as ImageProvider,
                        key: ValueKey(d.photoPath),
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        color: Colors.white,
                        colorBlendMode: BlendMode.saturation,
                      )
                    : Center(
                        key: const ValueKey('empty'),
                        child: Icon(
                          Icons.person_rounded,
                          size: 84,
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── back ─────────────────────────
  Widget _back() {
    final d = widget.data;
    final f = widget.focus;
    final backFocus = const {
      CardFocus.experience,
      CardFocus.position,
      CardFocus.notice,
      CardFocus.location,
    }.contains(f);

    final position = d.isFresher
        ? 'Student / Fresher'
        : (d.jobTitle.trim().isEmpty ? null : d.jobTitle.trim());
    final positionSub = d.isFresher
        ? 'Early career'
        : (d.company.trim().isEmpty ? 'Current role' : 'at ${d.company.trim()}');

    final rows = [
      (CardFocus.experience, Icons.timer_outlined, d.experienceTitle, 'Experience'),
      (CardFocus.position, Icons.work_outline_rounded, position, positionSub),
      (CardFocus.notice, Icons.event_available_outlined, d.notice, 'Notice period'),
      (CardFocus.location, Icons.location_on_outlined, d.location, 'Based in'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 40, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in rows) ...[
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: !backFocus || f == r.$1 ? 1 : 0.4,
              child: _backRow(r.$2, r.$3, r.$4, f == r.$1),
            ),
            const SizedBox(height: 24),
          ],
          const Spacer(),
          Center(child: _wordmark()),
        ],
      ),
    );
  }

  Widget _backRow(IconData icon, String? title, String sub, bool focused) {
    final empty = title == null || title.isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: Colors.white.withValues(alpha: empty ? 0.4 : 0.95)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                empty ? '—' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: empty ? 0.35 : 1),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              _focusLine(focused),
            ],
          ),
        ),
      ],
    );
  }
}
