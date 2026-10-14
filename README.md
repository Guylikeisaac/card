# SyncUp — Onboarding (Flutter frontend)

The mobile onboarding flow that runs **after phone + email verification**.

## Flow
1. **Identity card**: a glass SyncUp card pops up and asks for your **photo**. It then slides up to your **name**, slides up again to your **dream role**, and spins to reveal itself.
2. **Profile steps**: the card rotates on every step. Answers that belong on the back of the card (location, experience, notice period) flip it to its back face.
   - What brings you here? → How would you like to set up your profile? → *(Upload resume → parsing)* → Where are you based? → Tell us about yourself → Add your most recent experience *(skipped for freshers)* → What kind of role are you open to? → CTC → Notice period → Top 5 skills → Work links → Discover what drives you → Gender
3. **Verify with DigiLocker**: a blurred modal on the completion screen.

Frontend only. Resume parsing and the DigiLocker connection are mocked (see `ResumeStep._applyParsed` and `_DigiLockerDialog._connect`).

## Run
```bash
flutter pub get
flutter run
```

## Structure
```
lib/
  main.dart                       app entry (OnboardingFlow as home)
  theme/app_theme.dart            black & white tokens + Inter type
  models/onboarding_data.dart     all answers (ChangeNotifier)
  data/options.dart               cities, roles, skills, interests…
  widgets/profile_card.dart       3D glass card (front/back, sheen, flip)
  widgets/curtain_background.dart animated light-beam backdrop
  widgets/common.dart             Continue button, option tiles, fields, picker sheet
  onboarding/onboarding_flow.dart phase machine + card choreography
  onboarding/steps/               individual step screens
  onboarding/digilocker_dialog.dart
```
