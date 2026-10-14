import 'package:flutter/foundation.dart';

/// AdMob ad unit ids.
///
/// The defaults are Google's public *test* units, which always fill and are
/// safe to click during development. For a release build pass your own ids:
///
/// ```
/// flutter build apk --release \
///   --dart-define=ADMOB_BANNER_ANDROID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-xxx/yyy
/// ```
///
/// The AdMob *app* id lives in AndroidManifest.xml / Info.plist.
abstract final class AdIds {
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String get banner => _ios
      ? const String.fromEnvironment('ADMOB_BANNER_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/2435281174')
      : const String.fromEnvironment('ADMOB_BANNER_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/9214589741');

  static String get interstitial => _ios
      ? const String.fromEnvironment('ADMOB_INTERSTITIAL_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/4411468910')
      : const String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/1033173712');

  static String get rewarded => _ios
      ? const String.fromEnvironment('ADMOB_REWARDED_IOS',
          defaultValue: 'ca-app-pub-3940256099942544/1712485313')
      : const String.fromEnvironment('ADMOB_REWARDED_ANDROID',
          defaultValue: 'ca-app-pub-3940256099942544/5224354917');
}
