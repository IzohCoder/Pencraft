# Pencraft ProGuard / R8 rules

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift (SQLite ORM) — keep generated code
-keep class com.isaac.pencraft.** { *; }
-keepclassmembers class * extends androidx.sqlite.db.SupportSQLiteOpenHelper$Factory { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# RevenueCat
-keep class com.revenuecat.** { *; }

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# Gson / JSON (used by backup service)
-keepattributes Signature
-keepattributes *Annotation*

# Keep crash stack traces readable
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Flutter deferred components — we don't use them but Flutter's embedding
# references Play Core classes. Tell R8 to ignore missing ones.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
