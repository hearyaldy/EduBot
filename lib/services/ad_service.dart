import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/environment_config.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static final _config = EnvironmentConfig.instance;
  
  bool _isInitialized = false;
  bool _isEnabled = true;
  
  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  
  // Ad loading states
  bool _isBannerAdLoaded = false;
  bool _isLoadingInterstitial = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled && _config.isAdMobConfigured;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  BannerAd? get bannerAd => _bannerAd;

  // Get platform-specific ad unit IDs
  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return _config.admobBannerAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _config.admobBannerAdUnitIdIOS;
    }
    return '';
  }

  String get _interstitialAdUnitId {
    if (Platform.isAndroid) {
      return _config.admobInterstitialAdUnitIdAndroid;
    } else if (Platform.isIOS) {
      return _config.admobInterstitialAdUnitIdIOS;
    }
    return '';
  }

  // Initialize the Ad Service
  Future<void> initialize() async {
    if (_isInitialized || !_config.isAdMobConfigured) return;

    try {
      await MobileAds.instance.initialize();
      
      // Configure request configuration for better ad targeting
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        testDeviceIds: kDebugMode ? ['TEST_DEVICE_ID'] : [],
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      );
      
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      
      _isInitialized = true;
      
      // Pre-load an interstitial ad
      _loadInterstitialAd();
      
      if (_config.isDebugMode) {
        print('AdMob initialized successfully');
      }
    } catch (e) {
      if (_config.isDebugMode) {
        print('Failed to initialize AdMob: $e');
      }
      _isEnabled = false;
    }
  }

  // Enable/disable ads (useful for premium users)
  void setAdsEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      _disposeBannerAd();
      _disposeInterstitialAd();
    }
  }

  // Create and load banner ad
  Future<void> loadBannerAd() async {
    if (!isEnabled || _isBannerAdLoaded) return;

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          if (_config.isDebugMode) {
            print('Banner ad loaded successfully');
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          _bannerAd = null;
          if (_config.isDebugMode) {
            print('Banner ad failed to load: $error');
          }
        },
        onAdOpened: (ad) {
          if (_config.isDebugMode) {
            print('Banner ad opened');
          }
        },
        onAdClosed: (ad) {
          if (_config.isDebugMode) {
            print('Banner ad closed');
          }
        },
      ),
    );

    await _bannerAd?.load();
  }

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (!isEnabled || _isLoadingInterstitial || _isInterstitialAdReady) return;

    _isLoadingInterstitial = true;

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _isLoadingInterstitial = false;
          
          // Set full screen content callback
          _interstitialAd?.setImmersiveMode(true);
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              if (_config.isDebugMode) {
                print('Interstitial ad showed full screen content');
              }
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // Pre-load the next interstitial ad
              _loadInterstitialAd();
              if (_config.isDebugMode) {
                print('Interstitial ad dismissed');
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
              if (_config.isDebugMode) {
                print('Interstitial ad failed to show: $error');
              }
            },
          );
          
          if (_config.isDebugMode) {
            print('Interstitial ad loaded successfully');
          }
        },
        onAdFailedToLoad: (error) {
          _isLoadingInterstitial = false;
          _isInterstitialAdReady = false;
          if (_config.isDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
        },
      ),
    );
  }

  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (!isEnabled || !_isInterstitialAdReady || _interstitialAd == null) {
      return false;
    }

    try {
      await _interstitialAd?.show();
      return true;
    } catch (e) {
      if (_config.isDebugMode) {
        print('Error showing interstitial ad: $e');
      }
      return false;
    }
  }

  // Show interstitial ad with conditions (e.g., after certain actions)
  Future<bool> showInterstitialAdConditionally({
    required int actionCount,
    required int showAfterActions,
  }) async {
    if (actionCount > 0 && actionCount % showAfterActions == 0) {
      return await showInterstitialAd();
    }
    return false;
  }

  // Dispose banner ad
  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // Dispose interstitial ad
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }

  // Dispose all ads
  void dispose() {
    _disposeBannerAd();
    _disposeInterstitialAd();
  }

  // Get ad configuration status for debugging
  Map<String, dynamic> getAdStatus() {
    return {
      'is_initialized': _isInitialized,
      'is_enabled': _isEnabled,
      'is_configured': _config.isAdMobConfigured,
      'banner_ad_loaded': _isBannerAdLoaded,
      'interstitial_ad_ready': _isInterstitialAdReady,
      'is_loading_interstitial': _isLoadingInterstitial,
      'banner_ad_unit_id': _bannerAdUnitId,
      'interstitial_ad_unit_id': _interstitialAdUnitId,
    };
  }
}