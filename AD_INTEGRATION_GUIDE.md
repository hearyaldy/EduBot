# Ad Integration Guide for EduBot

## Overview

This guide documents the complete ad integration implementation for EduBot using Google Mobile Ads (AdMob). The implementation includes banner ads, interstitial ads, and ad-free premium experience.

## Features Implemented

### ✅ Google Mobile Ads Integration
- **Dependency Added**: `google_mobile_ads: ^5.1.0`
- **Platform Configuration**: Android & iOS native setup
- **Test Ad Units**: Configured with Google's test ad unit IDs

### ✅ Ad Service (`lib/services/ad_service.dart`)
- Singleton pattern for global ad management
- Banner ad loading and management
- Interstitial ad loading with auto-reload
- Conditional ad display based on user status
- Debug logging for development

### ✅ Banner Ads
- **Locations**: 
  - Home screen (below daily tips)
  - Ask Question screen (below token usage card)
- **Widget**: `AdBannerWidget` with loading states
- **Compact Version**: `CompactAdBannerWidget` for smaller spaces
- **Auto-hide**: For premium users and superadmin

### ✅ Interstitial Ads
- **Trigger**: Every 3rd question for free users
- **Smart Loading**: Pre-loads next ad after display
- **Conditional Display**: Based on action count and user status
- **Premium Bypass**: No interstitials for premium/superadmin users

### ✅ Ad-Free Premium Experience
- **Automatic Detection**: Ads hidden for premium users
- **Superadmin Override**: Ads disabled for developers
- **Settings Integration**: Premium upgrade mentions ad-free experience
- **Real-time Updates**: Ad status updates when premium status changes

## Configuration Files

### Environment Variables (`.env`)
```env
# Test Ad Unit IDs (for development)
ADMOB_APP_ID_ANDROID=ca-app-pub-3940256099942544~3347511713
ADMOB_APP_ID_IOS=ca-app-pub-3940256099942544~1458002511
ADMOB_BANNER_AD_UNIT_ID_ANDROID=ca-app-pub-3940256099942544/6300978111
ADMOB_BANNER_AD_UNIT_ID_IOS=ca-app-pub-3940256099942544/2934735716
ADMOB_INTERSTITIAL_AD_UNIT_ID_ANDROID=ca-app-pub-3940256099942544/1033173712
ADMOB_INTERSTITIAL_AD_UNIT_ID_IOS=ca-app-pub-3940256099942544/4411468910
```

### Android Configuration (`android/app/src/main/AndroidManifest.xml`)
```xml
<!-- AdMob App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-3940256099942544~3347511713"/>
```

### iOS Configuration (`ios/Runner/Info.plist`)
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

## How to Switch to Production

### 1. Get Your AdMob Account
- Sign up at [AdMob Console](https://apps.admob.com/)
- Create your app and get production ad unit IDs

### 2. Replace Test IDs in `.env`
```env
# Production Ad Unit IDs
ADMOB_APP_ID_ANDROID=ca-app-pub-YOUR_PUBLISHER_ID~YOUR_APP_ID
ADMOB_APP_ID_IOS=ca-app-pub-YOUR_PUBLISHER_ID~YOUR_APP_ID
ADMOB_BANNER_AD_UNIT_ID_ANDROID=ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_ID
ADMOB_BANNER_AD_UNIT_ID_IOS=ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_ID
ADMOB_INTERSTITIAL_AD_UNIT_ID_ANDROID=ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_ID
ADMOB_INTERSTITIAL_AD_UNIT_ID_IOS=ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_ID
```

### 3. Update Platform Configurations
- Update Android manifest with your production App ID
- Update iOS Info.plist with your production App ID

## Ad Placement Strategy

### Banner Ads
- **Home Screen**: Below daily tips - captures user attention without being intrusive
- **Question Screen**: Below input form - visible while users think/type
- **Non-intrusive**: Blends with app design using loading placeholders

### Interstitial Ads
- **Frequency**: Every 3rd question - balanced user experience vs revenue
- **Timing**: Before AI processing starts - natural break in user flow
- **Smart Loading**: Pre-loads next ad for instant display

## Revenue Optimization

### Current Settings
- **Free Users**: See all ads
- **Premium Users**: Ad-free experience (premium incentive)
- **Superadmin**: Ad-free for development/testing

### Recommendations
1. **A/B Test Frequency**: Try different interstitial frequencies (2nd, 4th question)
2. **Add Rewarded Ads**: Offer extra questions for watching ads
3. **Banner Placement**: Test different positions for better CTR
4. **Premium Pricing**: Consider ad-free as primary premium benefit

## Technical Implementation

### App Initialization
```dart
void main() async {
  // ... other initialization
  await AdService().initialize(); // Added to main.dart
}
```

### User Status Integration
```dart
// AppProvider manages ad state
_adService.setAdsEnabled(!_isPremium && !_isSuperadmin);
```

### Conditional Ad Display
```dart
// Banner ads automatically hide for premium users
if (appProvider.isPremium || appProvider.isSuperadmin) {
  return const SizedBox.shrink();
}
```

## Testing

### During Development
- Uses Google's test ad unit IDs
- Shows test ads that won't generate revenue
- Safe for testing without policy violations

### Before Production
1. Test ad loading and display
2. Verify premium ad-free experience
3. Test interstitial frequency
4. Check ad placement on different screen sizes

## Compliance & Best Practices

### AdMob Policies
- ✅ Test ads only during development
- ✅ Clear ad placement (not misleading)
- ✅ No accidental clicks (proper spacing)
- ✅ Child-safe content (educational app)

### User Experience
- ✅ Loading states for smooth experience
- ✅ Proper error handling
- ✅ Non-intrusive placement
- ✅ Premium value proposition

## Troubleshooting

### Common Issues
1. **Ads not showing**: Check internet connection, ad unit IDs, and app store approval
2. **Test ads in production**: Ensure you're using production ad unit IDs
3. **High latency**: Pre-load interstitials and use proper loading states
4. **Policy violations**: Review AdMob policies and content guidelines

### Debug Information
- Ad service provides `getAdStatus()` method for debugging
- Console logs in debug mode show ad loading states
- Environment config includes `isAdMobConfigured` validation

## Future Enhancements

### Potential Additions
1. **Rewarded Ads**: Extra questions for video views
2. **Native Ads**: More integrated ad experiences
3. **Advanced Targeting**: User behavior-based ad optimization
4. **A/B Testing**: Dynamic frequency and placement testing
5. **Analytics Integration**: Detailed revenue and performance tracking

The ad integration is now complete and ready for testing. For production deployment, simply replace the test ad unit IDs with your actual AdMob IDs.