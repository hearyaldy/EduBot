import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../providers/app_provider.dart';
import '../utils/environment_config.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  final AdService _adService = AdService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    await _adService.loadBannerAd();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Don't show ads for premium users or superadmin
        if (appProvider.isPremium || appProvider.isSuperadmin) {
          return const SizedBox.shrink();
        }

        // Don't show if ads are not enabled or configured
        if (!_adService.isEnabled) {
          return const SizedBox.shrink();
        }

        // Show loading placeholder while ad is loading
        if (_isLoading || !_adService.isBannerAdLoaded) {
          return Container(
            width: double.infinity,
            height: 60, // Standard banner ad height + padding
            color: Colors.grey[100],
            child: const Center(
              child: Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        final bannerAd = _adService.bannerAd;
        if (bannerAd == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          height: bannerAd.size.height.toDouble() + 16, // Ad height + padding
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: bannerAd.size.width.toDouble(),
              height: bannerAd.size.height.toDouble(),
              child: AdWidget(ad: bannerAd),
            ),
          ),
        );
      },
    );
  }
}

// Compact banner ad for smaller spaces
class CompactAdBannerWidget extends StatefulWidget {
  const CompactAdBannerWidget({super.key});

  @override
  State<CompactAdBannerWidget> createState() => _CompactAdBannerWidgetState();
}

class _CompactAdBannerWidgetState extends State<CompactAdBannerWidget> {
  final AdService _adService = AdService();
  final _config = EnvironmentConfig.instance;
  BannerAd? _compactBannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCompactBannerAd();
  }

  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return _config.admobBannerAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _config.admobBannerAdUnitIdIOS;
    }
    return '';
  }

  Future<void> _loadCompactBannerAd() async {
    if (!_adService.isEnabled) return;

    _compactBannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _compactBannerAd = null;
        },
      ),
    );

    await _compactBannerAd?.load();
  }

  @override
  void dispose() {
    _compactBannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Don't show ads for premium users or superadmin
        if (appProvider.isPremium || 
            appProvider.isSuperadmin || 
            !_adService.isEnabled ||
            !_isLoaded ||
            _compactBannerAd == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: _compactBannerAd!.size.width.toDouble(),
              height: _compactBannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _compactBannerAd!),
            ),
          ),
        );
      },
    );
  }
}