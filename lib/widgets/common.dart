import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

// ───────────────────────── Reveal ─────────────────────────
/// Fades + slides its child up after [delay].
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });
  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 650));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final v = Curves.easeOutCubic.transform(_c.value);
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * widget.offset),
              child: child,
            ),
          );
        },
      );
}

// ───────────────────────── Continue button ─────────────────────────
/// White pill when active; grey + skewed when disabled; skews on press.
class SyncButton extends StatefulWidget {
  const SyncButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.icon = Icons.arrow_forward_rounded,
    this.expand = false,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData? icon;
  final bool expand;
  final bool loading;

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && widget.onPressed != null && !widget.loading;
    final skew = (!active || _down) ? -0.22 : 0.0;
    final fg = active ? Colors.black : const Color(0xFF1A1A1A);

    Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
          )
        else ...[
          Flexible(
            child: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: 8),
            Icon(widget.icon, size: 17, color: fg),
          ],
        ],
      ],
    );

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _down = true) : null,
      onTapUp: active ? (_) => setState(() => _down = false) : null,
      onTapCancel: active ? () => setState(() => _down = false) : null,
      onTap: active
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 140),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: skew),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (_, k, child) => Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.skewX(k),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: active ? Colors.white : SC.disabledBtn,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.14),
                                blurRadius: 26,
                              )
                            ]
                          : const [],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            child: widget.expand
                ? SizedBox(width: double.infinity, child: label)
                : label,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Option tile ─────────────────────────
class OptionTile extends StatefulWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
  });
  final String title;
  final String? description;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<OptionTile> {
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
        scale: _down ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
              horizontal: 18, vertical: widget.description != null ? 16 : 18),
          decoration: BoxDecoration(
            color: s ? SC.fieldHi : SC.field,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: s ? SC.borderHi : SC.border, width: s ? 1.4 : 1),
            boxShadow: s
                ? [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.06),
                      spreadRadius: 3,
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SC.chip,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: s ? 0.14 : 0.05)),
                  ),
                  child: Icon(widget.icon,
                      size: 20, color: s ? Colors.white : SC.textDim),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: ST.body.copyWith(
                        fontWeight: s ? FontWeight.w600 : FontWeight.w500,
                        fontSize: widget.description != null ? 16.5 : 15.5,
                      ),
                    ),
                    if (widget.description != null) ...[
                      const SizedBox(height: 4),
                      Text(widget.description!, style: ST.small),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RadioMark(selected: s),
            ],
          ),
        ),
      ),
    );
  }
}

class RadioMark extends StatelessWidget {
  const RadioMark({super.key, required this.selected, this.size = 22});
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(
              color: selected ? Colors.white : const Color(0xFF5A5A60),
              width: 1.4),
        ),
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          child: Icon(Icons.check_rounded, size: size * 0.64, color: Colors.black),
        ),
      );
}

// ───────────────────────── Fields ─────────────────────────
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Flexible(
              child: Text(text,
                  style: ST.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (required)
              Text(' *', style: ST.label.copyWith(color: SC.textFaint)),
          ],
        ),
      );
}

InputDecoration syncInputDecoration({
  String? hint,
  IconData? prefixIcon,
  Widget? suffix,
  Widget? prefix,
  Color fill = SC.field,
  double radius = 14,
}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: ST.body.copyWith(color: SC.textFaint, fontWeight: FontWeight.w400),
    filled: true,
    fillColor: fill,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    prefixIcon: prefixIcon == null
        ? (prefix == null ? null : Center(widthFactor: 1, child: prefix))
        : Icon(prefixIcon, size: 19, color: SC.textDim),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 20),
    suffixIcon: suffix,
    enabledBorder: b(SC.border),
    disabledBorder: b(SC.border.withValues(alpha: 0.5)),
    focusedBorder: b(SC.borderHi, 1.4),
    border: b(SC.border),
  );
}

class SyncTextField extends StatelessWidget {
  const SyncTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.fill = SC.field,
    this.radius = 14,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Color fill;
  final double radius;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: ST.body,
        cursorColor: Colors.white,
        cursorWidth: 1.6,
        keyboardAppearance: Brightness.dark,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: syncInputDecoration(
          hint: hint,
          prefixIcon: prefixIcon,
          prefix: prefix,
          suffix: suffix,
          fill: fill,
          radius: radius,
        ),
      );
}

/// Tappable dropdown-like field.
class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.hint,
    this.value,
    this.onTap,
    this.icon = Icons.keyboard_arrow_down_rounded,
    this.hintBright = false,
  });
  final String hint;
  final String? value;
  final VoidCallback? onTap;
  final IconData icon;
  final bool hintBright;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              FocusManager.instance.primaryFocus?.unfocus();
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 54,
        padding: const EdgeInsets.only(left: 18, right: 14),
        decoration: BoxDecoration(
          color: SC.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: enabled ? SC.border : SC.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: value != null
                    ? ST.body
                    : ST.body.copyWith(
                        color: hintBright && enabled ? SC.text : SC.textFaint,
                        fontWeight:
                            hintBright ? FontWeight.w500 : FontWeight.w400,
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 19, color: enabled ? SC.textDim : SC.textFaint),
          ],
        ),
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(
          scale: 0.7 + 0.3 * v,
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
          decoration: BoxDecoration(
            color: SC.chip,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFF2C2C30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: ST.body.copyWith(fontSize: 13.5, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onRemove();
                },
                child: const Icon(Icons.close_rounded, size: 15, color: SC.textDim),
              ),
            ],
          ),
        ),
      );
}

// ───────────────────────── Logo ─────────────────────────
class SyncUpLogo extends StatelessWidget {
  const SyncUpLogo({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(size * 0.26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Center(
              child: CustomPaint(
                size: Size(size * 0.42, size * 0.38),
                painter: _TrianglePainter(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'SyncUp',
            style: GoogleFonts.inter(
              fontSize: size * 0.58,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),
        ],
      );
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(s.width / 2, 0)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(p, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ───────────────────────── Step scaffold ─────────────────────────
/// Title / subtitle / staggered body + pinned footer with Continue.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    required this.children,
    required this.canContinue,
    required this.onContinue,
    this.footerLeft,
    this.continueLabel = 'Continue',
  });
  final String title;
  final String? subtitle;
  final Widget? badge;
  final List<Widget> children;
  final bool canContinue;
  final VoidCallback onContinue;
  final Widget? footerLeft;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safe = kb ? 0.0 : MediaQuery.viewPaddingOf(context).bottom;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Reveal(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(title, style: ST.h1)),
                      if (badge != null) ...[
                        const SizedBox(width: 10),
                        Padding(padding: const EdgeInsets.only(top: 4), child: badge),
                      ],
                    ],
                  ),
                ),
                if (subtitle != null)
                  Reveal(
                    delay: const Duration(milliseconds: 70),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(subtitle!, style: ST.sub),
                    ),
                  ),
                const SizedBox(height: 22),
                for (var i = 0; i < children.length; i++)
                  Reveal(
                    delay: Duration(milliseconds: 150 + (i > 7 ? 7 : i) * 60),
                    child: children[i],
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 22),
          color: SC.border,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(22, 14, 22, 14 + safe),
          child: Row(
            children: [
              if (footerLeft != null) Flexible(child: footerLeft!),
              const Spacer(),
              SyncButton(
                label: continueLabel,
                enabled: canContinue,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FooterTextButton extends StatelessWidget {
  const FooterTextButton(this.label, {super.key, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(label,
              style: ST.label.copyWith(color: SC.textDim, fontWeight: FontWeight.w500)),
        ),
      );
}

// ───────────────────────── Picker sheet ─────────────────────────
Future<String?> showPickerSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
  bool searchable = false,
  bool allowCustom = false,
  Set<String> exclude = const {},
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _PickerSheet(
      title: title,
      options: options,
      selected: selected,
      searchable: searchable,
      allowCustom: allowCustom,
      exclude: exclude,
    ),
  );
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
    required this.allowCustom,
    required this.exclude,
  });
  final String title;
  final List<String> options;
  final String? selected;
  final bool searchable;
  final bool allowCustom;
  final Set<String> exclude;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim();
    final filtered = widget.options
        .where((o) =>
            !widget.exclude.contains(o) &&
            o.toLowerCase().contains(q.toLowerCase()))
        .toList();
    final showCustom = widget.allowCustom &&
        q.isNotEmpty &&
        !widget.options.any((o) => o.toLowerCase() == q.toLowerCase());
    final mq = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(maxHeight: mq.size.height * 0.75),
            decoration: BoxDecoration(
              color: const Color(0xF00E0E10),
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                  child: Text(widget.title,
                      style: ST.h1.copyWith(fontSize: 20, letterSpacing: -0.4)),
                ),
                if (widget.searchable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SyncTextField(
                      controller: _q,
                      hint: 'Search',
                      prefixIcon: Icons.search_rounded,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (showCustom) {
                          Navigator.pop(context, q);
                        } else if (filtered.isNotEmpty) {
                          Navigator.pop(context, filtered.first);
                        }
                      },
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                        bottom: mq.viewInsets.bottom > 0 ? 8 : mq.viewPadding.bottom + 8),
                    children: [
                      if (showCustom)
                        _row('Add "$q"', icon: Icons.add_rounded, onTap: () {
                          Navigator.pop(context, q);
                        }),
                      for (final o in filtered)
                        _row(o, selected: o == widget.selected, onTap: () {
                          Navigator.pop(context, o);
                        }),
                      if (filtered.isEmpty && !showCustom)
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Text('No matches', style: ST.small),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label,
      {bool selected = false, IconData? icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        highlightColor: Colors.white.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  label,
                  style: ST.body.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
