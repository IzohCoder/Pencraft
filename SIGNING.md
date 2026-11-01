# SIGNING.md — Release Signing Guide for Pencraft

> ⚠️ **Never commit a keystore file or passwords to git.**  
> Add `*.jks`, `*.keystore`, and `key.properties` to `.gitignore` before creating these files.

---

## Step 1 — Create a keystore (one-time, keep it safe forever)

```powershell
# Run from any directory. Store the resulting .jks file somewhere SAFE
# (password manager, encrypted drive — NOT in the project folder).
$env:JAVA_HOME = "C:\Program Files\Zulu\zulu-17"
& "C:\Program Files\Zulu\zulu-17\bin\keytool.exe" `
  -genkey -v `
  -keystore pencraft-release.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias pencraft
```

You will be prompted for:
- Keystore password (choose a strong one, save it in your password manager)
- Key alias password (can be same as keystore password)
- Name, organisation, city, country

---

## Step 2 — Create `key.properties` in `android/` (gitignored)

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=pencraft
storeFile=C:/path/to/pencraft-release.jks
```

> Use forward slashes on Windows in this file.

---

## Step 3 — Update `android/app/build.gradle.kts`

Add above the `android {}` block:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside `android {}`, add a `signingConfigs` block and update `buildTypes`:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

---

## Step 4 — Add to `.gitignore`

```
android/key.properties
*.jks
*.keystore
```

---

## Step 5 — Build the release APK

```powershell
$env:JAVA_HOME = "C:\Program Files\Zulu\zulu-17"
$env:ANDROID_HOME = "C:\android-sdk"
$env:PATH = "C:\flutter\bin;C:\android-sdk\platform-tools;C:\Program Files\Zulu\zulu-17\bin;$env:PATH"
$env:JAVA_TOOL_OPTIONS = "-Djavax.net.ssl.trustStore=C:\Users\9470h\.gradle\my-cacerts -Djavax.net.ssl.trustStorePassword=changeit"

Set-Location "C:\AppDevelopment\apps\invoice-maker"
& "C:\flutter\bin\flutter.bat" build apk --release
```

Output: `build\app\outputs\flutter-apk\app-release.apk`

---

## Step 6 — Build App Bundle (for Play Store upload)

```powershell
& "C:\flutter\bin\flutter.bat" build appbundle --release
```

Output: `build\app\outputs\bundle\release\app-release.aab`

Upload the `.aab` to Google Play Console.

---

## Keystore backup checklist

- [ ] Keystore file backed up to encrypted cloud storage
- [ ] Passwords saved in password manager
- [ ] `key.properties` NOT committed to git
- [ ] `pencraft-release.jks` NOT in project directory

> If you lose your keystore, you cannot update your app on the Play Store. You would have to publish a new app with a new package name. **Back it up.**
