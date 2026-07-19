import 'package:flutter/foundation.dart';

/// TEMPORARY test scaffolding — revert before merging.
///
/// When true, the app skips auth and onboarding and opens [CompleteSignup]
/// directly, so the camera / face-detection step can be exercised on a device
/// without going through sign-up each time.
///
/// Double-guarded by [kDebugMode] so a release build can never take this path
/// even if the flag is left on by accident.
const bool _forceCompleteSignupFlag = true;

bool get forceCompleteSignup => kDebugMode && _forceCompleteSignupFlag;
