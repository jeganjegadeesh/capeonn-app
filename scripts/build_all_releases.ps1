<#
.SYNOPSIS
    Automated multi-platform production build script for Capeonn Workplace Suite.
.DESCRIPTION
    Builds Android (AAB/APK), Web PWA, and Windows desktop artifacts with code obfuscation and debug symbol extraction.
.PARAMETER Targets
    Array of targets to build: 'all', 'android', 'web', 'windows'. Default is 'all'.
.PARAMETER Clean
    Switch to clean build artifacts before compiling.
.EXAMPLE
    .\build_all_releases.ps1 -Targets "web","windows" -Clean
#>
param (
    [string[]]$Targets = @("all"),
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Capeonn Workplace Suite - Multi-Platform Build Engine   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$AppDir = Resolve-Path "$PSScriptRoot\.."
Set-Location $AppDir

if ($Clean) {
    Write-Host "[1/5] Cleaning existing build artifacts..." -ForegroundColor Yellow
    flutter clean
}

Write-Host "[2/5] Fetching Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

$SymbolDir = Join-Path $AppDir "build\symbols"
if (-not (Test-Path $SymbolDir)) {
    New-Item -ItemType Directory -Path $SymbolDir -Force | Out-Null
}

$BuildAll = $Targets -contains "all"

# 1. Android Build
if ($BuildAll -or ($Targets -contains "android")) {
    Write-Host "[3/5] Building Android App Bundle (AAB) & Split APKs..." -ForegroundColor Green
    $AndroidSymbols = Join-Path $SymbolDir "android"
    
    Write-Host "  -> Compiling Play Store AAB..."
    flutter build appbundle --release --obfuscate --split-debug-info=$AndroidSymbols
    
    Write-Host "  -> Compiling Universal Split APKs..."
    flutter build apk --release --split-per-abi --obfuscate --split-debug-info=$AndroidSymbols
    
    Write-Host "  [OK] Android artifacts built successfully." -ForegroundColor Green
}

# 2. Web PWA Build
if ($BuildAll -or ($Targets -contains "web")) {
    Write-Host "[4/5] Building Web PWA (CanvasKit + Offline Service Worker)..." -ForegroundColor Green
    flutter build web --release --pwa-strategy=offline-first --web-renderer canvaskit
    Write-Host "  [OK] Web bundle output at: build/web/" -ForegroundColor Green
}

# 3. Windows Native Desktop Build
if ($BuildAll -or ($Targets -contains "windows")) {
    Write-Host "[5/5] Building Windows Native Desktop Executable..." -ForegroundColor Green
    $WinSymbols = Join-Path $SymbolDir "windows"
    flutter build windows --release --obfuscate --split-debug-info=$WinSymbols
    Write-Host "  [OK] Windows binaries output at: build/windows/x64/runner/Release/" -ForegroundColor Green
}

Write-Host "`nAll requested release builds completed successfully!" -ForegroundColor Green
Write-Host "Symbols cataloged in: $SymbolDir" -ForegroundColor Cyan
