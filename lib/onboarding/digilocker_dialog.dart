import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Returns true when the user tapped "Connect DigiLocker".
Future<bool?> showDigiLockerDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'DigiLocker',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 480),
    pageBuilder: (_, _, _) => const _DigiLockerDialog(),
    transitionBuilder: (_, a, _, child) {
      final v = Curves.easeOutCubic.transform(a.value);
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14 * v, sigmaY: 14 * v),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.55 * v)),
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 28 * (1 - v)),
                child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _DigiLockerDialog extends StatefulWidget {
  const _DigiLockerDialog();

  @override
  State<_DigiLockerDialog> createState() => _DigiLockerDialogState();
}

class _DigiLockerDialogState extends State<_DigiLockerDialog> {
  bool _loading = false;

  Future<void> _connect() async {
    setState(() => _loading = true);
    // Frontend-only: hook up the DigiLocker OAuth flow here.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) Navigator.pop(context, true);
  }

  Widget _tile(IconData icon, String label) => Expanded(
        child: Container(
          height: 104,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SC.border),
            color: SC.field,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: SC.chip,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Icon(icon, size: 17, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(label,
                  textAlign: TextAlign.center,
                  style: ST.body.copyWith(fontSize: 12.5, height: 1.3)),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: (w - 32).clamp(0, 420).toDouble(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 60),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, color: SC.textDim, size: 20),
              ),
            ),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: SC.field,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.cloud_rounded, size: 50, color: Colors.white),
                  Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.lock_rounded, size: 16, color: Colors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text('Identity verification',
                        overflow: TextOverflow.ellipsis,
                        style: ST.body.copyWith(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Verify with DigiLocker',
                textAlign: TextAlign.center,
                style: ST.h1.copyWith(fontSize: 24, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            Text(
              'Securely verify your identity and academic credentials in seconds. '
              'Connect your DigiLocker account to instantly validate your government ID '
              'and degree certificate, no manual document uploads required.',
              textAlign: TextAlign.center,
              style: ST.sub.copyWith(height: 1.55),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _tile(Icons.badge_outlined, 'Government ID'),
                const SizedBox(width: 10),
                _tile(Icons.school_outlined, 'Degree\ncertificate'),
                const SizedBox(width: 10),
                _tile(Icons.file_upload_outlined, 'No uploads\nneeded'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: SyncButton(
                label: 'Connect DigiLocker',
                icon: Icons.login_rounded,
                expand: true,
                loading: _loading,
                onPressed: _connect,
              ),
            ),
            const SizedBox(height: 16),
            Text('Powered by DigiLocker · Your data stays private',
                textAlign: TextAlign.center,
                style: ST.small.copyWith(color: SC.textFaint)),
          ],
        ),
      ),
    );
  }
}
