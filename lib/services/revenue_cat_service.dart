import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/app_config.dart';

class RevenueCatService {
  static bool _configured = false;

  static Future<void> configure() async {
    if (_configured) return;
    if (revenueCatMockMode || revenueCatApiKeyAndroid == 'YOUR_REVENUECAT_ANDROID_KEY') {
      _configured = true;
      return; // Mock mode — no real RC connection
    }
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(revenueCatApiKeyAndroid);
    await Purchases.configure(config);
    _configured = true;
  }

  /// Returns true if the user has active Pro entitlement.
  static Future<bool> isProActive() async {
    if (revenueCatMockMode) return false; // In mock mode, default to free
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(rcProEntitlement);
    } catch (_) {
      return false;
    }
  }

  /// Fetch available packages for the paywall.
  static Future<List<Package>> getPackages() async {
    if (revenueCatMockMode) return [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  /// Purchase a package. Returns true on success.
  static Future<bool> purchase(Package package) async {
    if (revenueCatMockMode) return false;
    try {
      await Purchases.purchasePackage(package);
      return true;
    } on PurchasesErrorCode catch (_) {
      return false;
    }
  }

  /// Restore purchases. Returns true if Pro restored.
  static Future<bool> restorePurchases() async {
    if (revenueCatMockMode) return false;
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey(rcProEntitlement);
    } catch (_) {
      return false;
    }
  }
}
