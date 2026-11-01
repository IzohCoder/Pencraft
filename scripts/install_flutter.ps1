# Flutter Install Script
# Run after flutter_download.zip is complete (1849 MB)
# Usage: .\install_flutter.ps1

$ErrorActionPreference = "Stop"

$zipPath = "C:\AppDevelopment\flutter_download.zip"
$installDir = "C:\"
$flutterBin = "C:\flutter\bin"

Write-Host "=== Installing Flutter SDK ==="
Write-Host "Source: $zipPath ($([math]::Round((Get-Item $zipPath).Length/1MB,1)) MB)"

# Extract (flutter zip extracts to a 'flutter' folder)
Write-Host "Extracting... this may take 2-3 minutes"
Expand-Archive -Path $zipPath -DestinationPath $installDir -Force

Write-Host "Extracted. Flutter should be at: C:\flutter"
if (-not (Test-Path "C:\flutter\bin\flutter.bat")) {
  Write-Host "ERROR: flutter.bat not found. Listing C:\flutter:"
  Get-ChildItem "C:\flutter" | Select-Object Name
  exit 1
}

# Add to PATH (user level)
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*C:\flutter\bin*") {
  [System.Environment]::SetEnvironmentVariable("PATH", "C:\flutter\bin;$userPath", "User")
  Write-Host "Added C:\flutter\bin to user PATH"
}
$env:PATH = "C:\flutter\bin;$env:PATH"

# Configure Flutter
Write-Host "Configuring Flutter..."
& "C:\flutter\bin\flutter.bat" config --android-sdk "C:\android-sdk"
& "C:\flutter\bin\flutter.bat" config --android-studio-dir "C:\Program Files\Android\Android Studio"

# Set no-analytics for CI
& "C:\flutter\bin\flutter.bat" config --no-analytics

# Accept Android licenses
Write-Host "Accepting Flutter Android licenses..."
$env:JAVA_HOME = "C:\Program Files\Zulu\zulu-17"
"y`ny`ny`ny`n" | & "C:\flutter\bin\flutter.bat" doctor --android-licenses 2>&1 | Out-Null

# Flutter doctor
Write-Host ""
Write-Host "=== Flutter Doctor ==="
& "C:\flutter\bin\flutter.bat" doctor -v

Write-Host ""
Write-Host "=== Flutter install COMPLETE ==="
Write-Host "Run: cd C:\AppDevelopment\apps\invoice-maker && flutter create . --org com.isaac --project-name pencraft --platforms android"
