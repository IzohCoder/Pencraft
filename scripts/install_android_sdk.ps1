# Android SDK Install Script
# Run after cmdline-tools-download.zip is ready

param(
  [string]$AndroidHome = "C:\android-sdk",
  [string]$JavaHome = "C:\Program Files\Zulu\zulu-17"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Installing Android SDK cmdline-tools ==="

# 1. Extract
$zipPath = "$AndroidHome\cmdline-tools-download.zip"
$extractTemp = "$AndroidHome\cmdline-tools-tmp"
$targetPath = "$AndroidHome\cmdline-tools\latest"

if (Test-Path $extractTemp) { Remove-Item $extractTemp -Recurse -Force }
Write-Host "Extracting cmdline-tools..."
Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force

# The zip extracts to a folder named "cmdline-tools" inside
$innerFolder = "$extractTemp\cmdline-tools"
if (-not (Test-Path $innerFolder)) {
  Write-Host "ERROR: Expected $innerFolder to exist after extraction"
  Get-ChildItem $extractTemp | Select-Object Name
  exit 1
}

# Move to final location
if (Test-Path $targetPath) { Remove-Item $targetPath -Recurse -Force }
New-Item -ItemType Directory -Path (Split-Path $targetPath) -Force | Out-Null
Move-Item $innerFolder $targetPath
Remove-Item $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "cmdline-tools installed at: $targetPath"

# 2. Set environment variables
$env:ANDROID_HOME = $AndroidHome
$env:JAVA_HOME = $JavaHome
$env:PATH = "$AndroidHome\cmdline-tools\latest\bin;$AndroidHome\platform-tools;$env:PATH"

[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $AndroidHome, "User")
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*android-sdk\cmdline-tools*") {
  [System.Environment]::SetEnvironmentVariable("PATH", 
    "$AndroidHome\cmdline-tools\latest\bin;$AndroidHome\platform-tools;$userPath", "User")
}

Write-Host "ANDROID_HOME set to: $AndroidHome"

# 3. Accept licenses
Write-Host "Accepting Android SDK licenses..."
$sdkmanager = "$targetPath\bin\sdkmanager.bat"
"y`ny`ny`ny`ny`ny`ny`n" | & $sdkmanager --sdk_root=$AndroidHome --licenses 2>&1 | Out-Null
Write-Host "Licenses accepted."

# 4. Install required SDK components
Write-Host "Installing platform-tools, build-tools;35.0.0, platforms;android-35..."
& $sdkmanager --sdk_root=$AndroidHome "platform-tools" "build-tools;35.0.0" "platforms;android-35" 2>&1 | 
  Where-Object { $_ -notmatch "^\[" }  # filter progress bars

Write-Host ""
Write-Host "=== Android SDK install complete ==="
Write-Host "ANDROID_HOME: $AndroidHome"
Write-Host "Installed components:"
& $sdkmanager --sdk_root=$AndroidHome --list_installed 2>&1 | Select-String "build-tools|platform-tools|platforms"
