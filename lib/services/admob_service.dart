import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

class AdMobService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (!enableAds) return;
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Creates and loads a banner ad.
  /// The caller is responsible for disposing the ad.
  static BannerAd createBannerAd({required AdListener listener}) {
    return BannerAd(
      adUnitId: admobBannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => listener.onAdLoaded?.call(),
        onAdFailedToLoad: (_, error) => listener.onAdFailedToLoad?.call(error),
      ),
    )..load();
  }
}

class AdListener {
  const AdListener({this.onAdLoaded, this.onAdFailedToLoad});

  final VoidCallback? onAdLoaded;
  final void Function(LoadAdError error)? onAdFailedToLoad;
}

/// A banner ad widget that loads and displays an AdMob banner.
/// Only shown when [enableAds] is true and the user is not Pro.
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key, this.isPro = false});

  final bool isPro;

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!enableAds || widget.isPro) return;
    _ad = AdMobService.createBannerAd(
      listener: AdListener(
        onAdLoaded: () {
          if (mounted) setState(() => _loaded = true);
        },
      ),
    );
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!enableAds || widget.isPro || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
