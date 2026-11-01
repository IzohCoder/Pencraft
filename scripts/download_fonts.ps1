# Download required fonts for Pencraft
# Run this script from C:\AppDevelopment\apps\invoice-maker
# Fonts go in: assets/fonts/

$fontsDir = "C:\AppDevelopment\apps\invoice-maker\assets\fonts"
New-Item -ItemType Directory -Force -Path $fontsDir | Out-Null

# ---- Inter (Google Fonts) ----
$interBase = "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
$interZip = "$env:TEMP\inter.zip"
Write-Host "Downloading Inter..."
Invoke-WebRequest -Uri $interBase -OutFile $interZip -UseBasicParsing
Expand-Archive -Path $interZip -DestinationPath "$env:TEMP\inter" -Force
Copy-Item "$env:TEMP\inter\Inter Desktop\Inter-Regular.otf" "$fontsDir\Inter-Regular.ttf"
Copy-Item "$env:TEMP\inter\Inter Desktop\Inter-Medium.otf" "$fontsDir\Inter-Medium.ttf"
Copy-Item "$env:TEMP\inter\Inter Desktop\Inter-SemiBold.otf" "$fontsDir\Inter-SemiBold.ttf"
Copy-Item "$env:TEMP\inter\Inter Desktop\Inter-Bold.otf" "$fontsDir\Inter-Bold.ttf"

# ---- DM Serif Display (Google Fonts CDN) ----
$dmBase = "https://fonts.gstatic.com/s/dmserifdisplay/v11/-nFnOHM81r4j6k0gjALR8uVcfKPXQzsV3mFR.woff2"
Write-Host "Downloading DM Serif Display..."
Invoke-WebRequest -Uri $dmBase -OutFile "$fontsDir\DMSerifDisplay-Regular.ttf" -UseBasicParsing
$dmItalic = "https://fonts.gstatic.com/s/dmserifdisplay/v11/-nFsOHM81r4j6k0gjALR8uVcfKPXQzs.woff2"
Invoke-WebRequest -Uri $dmItalic -OutFile "$fontsDir\DMSerifDisplay-Italic.ttf" -UseBasicParsing

# ---- Noto Sans (for PDF Unicode coverage) ----
$notoBase = "https://fonts.gstatic.com/s/notosans/v36/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjc5a7du3mhPy0.woff2"
Write-Host "Downloading Noto Sans..."
Invoke-WebRequest -Uri $notoBase -OutFile "$fontsDir\NotoSans-Regular.ttf" -UseBasicParsing
$notoBold = "https://fonts.gstatic.com/s/notosans/v36/o-0mIpQlx3QUlC5A4PNB6Ryti20_6n1iPHjc5a7du3mhPy0.woff2"
Invoke-WebRequest -Uri $notoBold -OutFile "$fontsDir\NotoSans-Bold.ttf" -UseBasicParsing

Write-Host "Fonts downloaded to $fontsDir"
Get-ChildItem $fontsDir | Select-Object Name, @{N='KB';E={[math]::Round($_.Length/1KB,1)}}
