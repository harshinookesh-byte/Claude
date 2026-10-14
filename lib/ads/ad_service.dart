import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Ads used by the game: a banner, an interstitial between fashion shows and
/// a rewarded video for coins / free unlocks.
///
/// [NoAdService] is used on platforms without AdMob (web, desktop) and in
/// tests, so the rest of the app never talks to the plugin directly.
abstract class AdService extends ChangeNotifier {
  /// Whether a rewarded video is loaded and can be shown right now.
  bool get rewardedReady;

  /// Shows a rewarded video. Completes with true only if the viewer earned
  /// the reward (watched to the end).
  Future<bool> showRewarded();

  /// Called when a fashion show finishes. Shows an interstitial at most
  /// every [InterstitialPacing.showsBetween] shows and never more often than
  /// [InterstitialPacing.minGap], so ads don't interrupt every round.
  Future<void> onShowFinished();

  /// A banner for the bottom of a screen, or an empty box if none is loaded.
  Widget banner();
}

abstract final class InterstitialPacing {
  static const showsBetween = 2;
  static const minGap = Duration(seconds: 90);
}

class NoAdService extends AdService {
  @override
  bool get rewardedReady => false;

  @override
  Future<bool> showRewarded() async => false;

  @override
  Future<void> onShowFinished() async {}

  @override
  Widget banner() => const SizedBox.shrink();
}

class AdMobService extends AdService {
  bool _canRequestAds = false;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  int _showsSinceInterstitial = 0;
  DateTime _lastInterstitial = DateTime.fromMillisecondsSinceEpoch(0);
  int _retry = 0;

  /// Gathers GDPR/UMP consent where required, then starts the SDK and
  /// preloads the full-screen ads. Safe to call without awaiting.
  Future<void> init() async {
    final consent = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) debugPrint('Consent form: ${error.message}');
        consent.complete();
      }),
      (error) {
        debugPrint('Consent info: ${error.message}');
        consent.complete();
      },
    );
    await consent.future;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (!_canRequestAds) return;
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _loadRewarded();
    notifyListeners();
  }

  // ---------------- interstitial ----------------

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: ${error.message}');
          _interstitial = null;
          _retryLater(_loadInterstitial);
        },
      ),
    );
  }

  @override
  Future<void> onShowFinished() async {
    _showsSinceInterstitial++;
    final ad = _interstitial;
    if (ad == null ||
        _showsSinceInterstitial < InterstitialPacing.showsBetween ||
        DateTime.now().difference(_lastInterstitial) <
            InterstitialPacing.minGap) {
      return;
    }
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        closed.complete();
      },
    );
    _interstitial = null;
    _showsSinceInterstitial = 0;
    _lastInterstitial = DateTime.now();
    await ad.show();
    await closed.future;
    _loadInterstitial();
  }

  // ---------------- rewarded ----------------

  void _loadRewarded() {
    RewardedAd.load(
      adUnitId: AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _retry = 0;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded failed: ${error.message}');
          _rewarded = null;
          notifyListeners();
          _retryLater(_loadRewarded);
        },
      ),
    );
  }

  @override
  bool get rewardedReady => _rewarded != null;

  @override
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) return false;
    _rewarded = null;
    notifyListeners();
    var earned = false;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        closed.complete();
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    await closed.future;
    _loadRewarded();
    return earned;
  }

  void _retryLater(VoidCallback load) {
    // Back off 5s, 10s, 20s ... capped at 2 minutes.
    final delay = Duration(seconds: (5 << _retry).clamp(5, 120));
    _retry = (_retry + 1).clamp(0, 5);
    Timer(delay, load);
  }

  // ---------------- banner ----------------

  @override
  Widget banner() => _canRequestAds ? const _Banner() : const SizedBox.shrink();
}

class _Banner extends StatefulWidget {
  const _Banner();

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad == null) _load();
  }

  Future<void> _load() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}

/// Makes the [AdService] available to the widget tree.
class AdScope extends InheritedNotifier<AdService> {
  const AdScope({super.key, required AdService ads, required super.child})
      : super(notifier: ads);

  static AdService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdScope>()!.notifier!;

  static AdService read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AdScope>()!.notifier!;
}

/// AdMob only exists on Android and iOS.
bool get adsSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);
