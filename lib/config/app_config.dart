// App-level configuration for Pencraft.

import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Feature flags
// ---------------------------------------------------------------------------
const bool enableOnboarding = true;
const bool enablePaywall = true;
const bool enableAds = true;
const bool enableIAP = true;

// ---------------------------------------------------------------------------
// App identity
// ---------------------------------------------------------------------------
const String appName = 'Pencraft';
const String appTagline = 'Professional invoices in seconds';
const String appSupportEmail = 'support@pencraft.app';
const String appPrivacyPolicyUrl = 'https://pencraft.app/privacy';
const String appTermsUrl = 'https://pencraft.app/terms';
const String appPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.isaac.pencraft';

// ---------------------------------------------------------------------------
// RevenueCat — MOCK mode for MVP
// ---------------------------------------------------------------------------
const String revenueCatApiKeyAndroid = 'YOUR_REVENUECAT_ANDROID_KEY';
const bool revenueCatMockMode = true;

const String rcProEntitlement = 'pro';
const String rcMonthlyEntitlement = 'pro_monthly';
const String rcAnnualEntitlement = 'pro_annual';
const String rcLifetimeEntitlement = 'pro_lifetime';

// ---------------------------------------------------------------------------
// AdMob — TEST IDs for MVP
// ---------------------------------------------------------------------------
const String admobAppId = 'ca-app-pub-3940256099942544~3347511713';
const String admobBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

// ---------------------------------------------------------------------------
// Monetization limits
// ---------------------------------------------------------------------------
const int freeMonthlyDocumentLimit = 5;
const int freeTemplateCount = 1;

// ---------------------------------------------------------------------------
// Debug
// ---------------------------------------------------------------------------
bool get isDebugMode => kDebugMode;
