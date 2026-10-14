import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onboarding/onboarding_flow.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: SC.bg,
    ),
  );
  runApp(const SyncUpApp());
}

class SyncUpApp extends StatelessWidget {
  const SyncUpApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SyncUp',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // In the real app, push OnboardingFlow right after email verification.
        home: const OnboardingFlow(),
      );
}
