import 'package:flutter/foundation.dart';

enum LinkKind { linkedin, github, figma, behance, dribbble, web }

class WorkLink {
  const WorkLink(this.url);
  final String url;

  String get host {
    final h = Uri.tryParse(url)?.host ?? url;
    return h.startsWith('www.') ? h.substring(4) : h;
  }

  LinkKind get kind {
    final h = host.toLowerCase();
    if (h.contains('linkedin')) return LinkKind.linkedin;
    if (h.contains('github')) return LinkKind.github;
    if (h.contains('figma')) return LinkKind.figma;
    if (h.contains('behance')) return LinkKind.behance;
    if (h.contains('dribbble')) return LinkKind.dribbble;
    return LinkKind.web;
  }

  String get title {
    switch (kind) {
      case LinkKind.linkedin:
        return 'LinkedIn';
      case LinkKind.github:
        return 'GitHub';
      case LinkKind.figma:
        return 'Figma';
      case LinkKind.behance:
        return 'Behance';
      case LinkKind.dribbble:
        return 'Dribbble';
      case LinkKind.web:
        final parts = host.split('.');
        final name =
            parts.length > 1 ? parts.sublist(0, parts.length - 1).join('.') : host;
        if (name.isEmpty) return host;
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}

/// All onboarding answers. Frontend-only state; wire to your API later.
class OnboardingData extends ChangeNotifier {
  // Identity card
  String? photoPath;
  String name = '';
  String dreamRole = '';
  bool verified = false;

  // Steps
  String? intent;
  String? setupMode;
  String? resumeName;
  bool resumeParsed = false;
  String? location;
  String? level;
  String jobTitle = '';
  String? department;
  String? industry;
  String? employmentType;
  String company = '';
  DateTime? from;
  DateTime? to;
  bool currentlyWorking = false;
  final List<String> roles = [];
  String currentCtc = '';
  String expectedCtc = '';
  String? notice;
  final List<String> skills = [];
  final List<WorkLink> links = [];
  final Set<String> interests = {};
  String? gender;

  void set(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  bool get usesResume => setupMode == 'Upload Resume';
  bool get isFresher => level == 'Student / Fresher';

  String get firstName {
    final n = name.trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  /// "3+ Years" style label for the back of the card.
  String? get experienceTitle {
    if (isFresher) return 'Fresher';
    if (from == null) return null;
    final end = currentlyWorking ? DateTime.now() : (to ?? DateTime.now());
    final months = (end.year - from!.year) * 12 + end.month - from!.month;
    if (months >= 12) return '${months ~/ 12}+ Years';
    if (months <= 0) return '< 1 Month';
    return '$months ${months == 1 ? 'Month' : 'Months'}';
  }
}
