import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncup_onboarding/onboarding/onboarding_flow.dart';
import 'package:syncup_onboarding/theme/app_theme.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> tapText(WidgetTester t, String s) async {
    await t.ensureVisible(find.text(s).last);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text(s).last);
    await t.pump(const Duration(milliseconds: 100));
  }

  Future<void> cont(WidgetTester t) async {
    await t.pump(const Duration(milliseconds: 100));
    // The offscreen steps sheet also has a Continue; pick the on-screen one.
    final all = find.text('Continue');
    final idx = List.generate(all.evaluate().length, (i) => i)
        .firstWhere((i) => t.getRect(all.at(i)).top < 844);
    await t.ensureVisible(all.at(idx));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(all.at(idx));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('walks the full manual flow on a phone', (t) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    // Test font (Ahem) glyphs are far wider than Inter; ignore overflow noise.
    final orig = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      orig?.call(d);
    };
    await t.pumpWidget(MaterialApp(theme: buildTheme(), home: const OnboardingFlow()));
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Add your photo'), findsOneWidget);
    await tapText(t, 'Skip for now');
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.enterText(find.byType(TextField).last, 'Arjun Mehta');
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(const ValueKey('identity-next')));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.enterText(find.byType(TextField).last, 'Software Engineer');
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(const ValueKey('identity-next')).last);
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('What brings you here?'), findsOneWidget);
    await tapText(t, "I'm actively looking for a job");
    await cont(t);
    await tapText(t, 'Fill Manually');
    await cont(t);
    expect(find.text('Where are you based?'), findsOneWidget);
    await t.tap(find.byType(TextField).last);
    await t.pump(const Duration(milliseconds: 400));
    await tapText(t, 'Mumbai, Maharashtra');
    await cont(t);
    await tapText(t, 'Student / Fresher');
    await cont(t);
    expect(find.text('What kind of role are you open to?'), findsOneWidget);
    await t.tap(find.textContaining('Add job role'));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.enterText(find.byType(TextField).last, 'Data Analyst');
    await t.pump(const Duration(milliseconds: 200));
    await tapText(t, 'Data Analyst');
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await cont(t);
    await tapText(t, 'Skip');
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await tapText(t, '1 month');
    await cont(t);
    await tapText(t, 'Python');
    await cont(t);
    await tapText(t, 'Skip');
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    for (final s in ['Career', 'Design', 'Finance']) {
      await tapText(t, s);
    }
    await cont(t);
    expect(find.text("What's your gender?"), findsOneWidget);
    await tapText(t, 'Prefer not to say');
    await cont(t);
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    FlutterError.onError = orig;
    expect(find.text('Verify with DigiLocker'), findsOneWidget);
  });
}

