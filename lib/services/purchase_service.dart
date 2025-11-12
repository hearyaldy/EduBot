import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  // Product IDs (must match what's configured in App Store Connect and Google Play Console)
  static const String premiumMonthlyId = 'edubot_premium_monthly';
  static const String premiumYearlyId = 'edubot_premium_yearly';

  // Singleton pattern
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isInitialized = false;
  bool _isPremium = false;

  SharedPreferences? _prefs;
  static const String _premiumStatusKey = 'is_premium_iap';
  static const String _purchaseDateKey = 'premium_purchase_date';
  static const String _expiryDateKey = 'premium_expiry_date';

  // Callback for when premium status changes
  Function(bool isPremium)? onPremiumStatusChanged;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();

    // Load saved premium status
    _isPremium = _prefs?.getBool(_premiumStatusKey) ?? false;

    // Check if IAP is available
    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('In-App Purchase not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );

    // Load products
    await _loadProducts();

    // Restore purchases on initialization
    await restorePurchases();

    _isInitialized = true;
    debugPrint('PurchaseService initialized successfully');
  }

  Future<void> _loadProducts() async {
    try {
      const productIds = {premiumMonthlyId, premiumYearlyId};
      final response = await _iap.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      debugPrint('Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      // Verify purchase (in production, verify with your backend)
      final valid = await _verifyPurchase(purchaseDetails);

      if (valid) {
        await _deliverProduct(purchaseDetails);
      }
    }

    if (purchaseDetails.status == PurchaseStatus.error) {
      debugPrint('Purchase error: ${purchaseDetails.error}');
    }

    if (purchaseDetails.status == PurchaseStatus.canceled) {
      debugPrint('Purchase canceled by user');
    }

    // Complete the purchase
    if (purchaseDetails.pendingCompletePurchase) {
      await _iap.completePurchase(purchaseDetails);
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In production, you should verify the purchase with your backend
    // For now, we'll accept all purchases from the stores
    // You can implement receipt verification here

    // iOS: purchaseDetails.verificationData.serverVerificationData
    // Android: purchaseDetails.verificationData.serverVerificationData

    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    // Grant premium access
    _isPremium = true;
    await _prefs?.setBool(_premiumStatusKey, true);
    await _prefs?.setString(_purchaseDateKey, DateTime.now().toIso8601String());

    // Calculate expiry date (30 days for monthly, 365 for yearly)
    final isMonthly = purchaseDetails.productID == premiumMonthlyId;
    final expiryDate = DateTime.now().add(
      Duration(days: isMonthly ? 30 : 365),
    );
    await _prefs?.setString(_expiryDateKey, expiryDate.toIso8601String());

    debugPrint('Premium access granted until: $expiryDate');

    // Notify listeners
    onPremiumStatusChanged?.call(true);
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isInitialized) {
      debugPrint('PurchaseService not initialized');
      return false;
    }

    try {
      final product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      final purchaseParam = PurchaseParam(productDetails: product);

      // Purchase subscription or consumable
      bool success;
      if (productId == premiumMonthlyId || productId == premiumYearlyId) {
        success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }

      return success;
    } catch (e) {
      debugPrint('Error purchasing product: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isInitialized) return;

    try {
      await _iap.restorePurchases();
      debugPrint('Purchases restored');
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  /// Check if subscription is still valid
  Future<bool> checkSubscriptionStatus() async {
    if (!_isPremium) return false;

    final expiryString = _prefs?.getString(_expiryDateKey);
    if (expiryString == null) return false;

    final expiryDate = DateTime.parse(expiryString);
    final isValid = DateTime.now().isBefore(expiryDate);

    if (!isValid) {
      // Subscription expired
      _isPremium = false;
      await _prefs?.setBool(_premiumStatusKey, false);
      onPremiumStatusChanged?.call(false);
      debugPrint('Subscription expired');
    }

    return isValid;
  }

  /// Get product details
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get monthly subscription product
  ProductDetails? get monthlyProduct => getProduct(premiumMonthlyId);

  /// Get yearly subscription product
  ProductDetails? get yearlyProduct => getProduct(premiumYearlyId);

  /// Check if user has premium
  bool get isPremium => _isPremium;

  /// Get all available products
  List<ProductDetails> get products => List.unmodifiable(_products);

  /// Get purchase date
  DateTime? get purchaseDate {
    final dateString = _prefs?.getString(_purchaseDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  /// Get expiry date
  DateTime? get expiryDate {
    final dateString = _prefs?.getString(_expiryDateKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  /// Format price for display
  String formatPrice(ProductDetails product) {
    return product.price;
  }

  /// Get savings percentage for yearly vs monthly
  String getSavingsPercentage() {
    if (monthlyProduct == null || yearlyProduct == null) return '0%';

    // Extract numeric price (basic implementation)
    // In production, use proper price parsing based on currency
    try {
      final monthlyPrice = double.tryParse(
            monthlyProduct!.price.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      final yearlyPrice = double.tryParse(
            yearlyProduct!.price.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;

      if (monthlyPrice == 0) return '0%';

      final yearlyCostAsMonthly = monthlyPrice * 12;
      final savings = ((yearlyCostAsMonthly - yearlyPrice) / yearlyCostAsMonthly) * 100;

      return '${savings.toStringAsFixed(0)}%';
    } catch (e) {
      return '0%';
    }
  }

  /// Manual override for testing (use only in development)
  Future<void> setTestPremiumStatus(bool isPremium) async {
    if (kDebugMode) {
      _isPremium = isPremium;
      await _prefs?.setBool(_premiumStatusKey, isPremium);

      if (isPremium) {
        await _prefs?.setString(
          _purchaseDateKey,
          DateTime.now().toIso8601String(),
        );
        await _prefs?.setString(
          _expiryDateKey,
          DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        );
      }

      onPremiumStatusChanged?.call(isPremium);
      debugPrint('Test premium status set to: $isPremium');
    }
  }

  /// Clean up
  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
