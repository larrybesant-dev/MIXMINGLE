#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates VS Code and Flutter development environment configuration.
.DESCRIPTION
    Checks all configuration files, dependencies, and development tools.
.EXAMPLE
    .\validate-config.ps1
#>

Write-Host "=" * 60
Write-Host "Configuration Validator (VS Code and Flutter)" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host ""

$errors = @()
$warnings = @()
$success = @()

# Check Flutter
Write-Host "📦 Checking Flutter..." -ForegroundColor Yellow
try {
  $flutterVersion = flutter --version 2>&1
  if ($LASTEXITCODE -eq 0) {
    $success += "✅ Flutter: Installed"
    Write-Host $flutterVersion -ForegroundColor Green
  }
  else {
    $errors += "❌ Flutter: Not found or not in PATH"
  }
}
catch {
  $errors += "❌ Flutter: Command failed - $_"
}
Write-Host ""

# Check Dart
Write-Host "🎯 Checking Dart..." -ForegroundColor Yellow
try {
  $dartVersion = dart --version 2>&1
  if ($LASTEXITCODE -eq 0) {
    $success += "✅ Dart: Installed"
    Write-Host $dartVersion -ForegroundColor Green
  }
  else {
    $errors += "❌ Dart: Not accessible"
  }
}
catch {
  $errors += "❌ Dart: Command failed"
}
Write-Host ""

# Check Firebase CLI
Write-Host "🔥 Checking Firebase CLI..." -ForegroundColor Yellow
try {
  $firebaseVersion = firebase --version 2>&1
  if ($LASTEXITCODE -eq 0) {
    $success += "✅ Firebase CLI: Installed"
    Write-Host "Version: $firebaseVersion" -ForegroundColor Green
  }
  else {
    $warnings += "⚠️  Firebase CLI: Not found (optional if not deploying)"
  }
}
catch {
  $warnings += "⚠️  Firebase CLI: Not installed"
}
Write-Host ""

# Check configuration files
Write-Host "📋 Checking Configuration Files..." -ForegroundColor Yellow

$configFiles = @(
  ".vscode\settings.json",
  ".vscode\launch.json",
  ".vscode\tasks.json",
  ".vscode\extensions.json",
  "MixMingle.code-workspace",
  "analysis_options.yaml",
  "pubspec.yaml",
  "firebase.json"
)

foreach ($file in $configFiles) {
  if (Test-Path $file) {
    $success += "✅ Found: $file"
    Write-Host "  ✅ $file" -ForegroundColor Green
  }
  else {
    $errors += "❌ Missing: $file"
    Write-Host "  ❌ $file" -ForegroundColor Red
  }
}
Write-Host ""

# Check environment files
Write-Host "🔐 Checking Environment Files..." -ForegroundColor Yellow

if (Test-Path ".env") {
  $success += "✅ .env: Exists"
  Write-Host "  ✅ .env (configured)" -ForegroundColor Green
}
elseif (Test-Path ".env.example") {
  $warnings += "⚠️  .env: Not found (copy from .env.example)"
  Write-Host "  ⚠️  .env not found - Copy from .env.example" -ForegroundColor Yellow
}
else {
  $errors += "❌ .env.example: Missing"
}
Write-Host ""

# Check dependencies
Write-Host "📚 Checking Dependencies..." -ForegroundColor Yellow

try {
  $pubspecFile = Get-Content pubspec.yaml
  if ($pubspecFile -match "firebase_core") {
    $success += "✅ Firebase Dependencies: Configured"
    Write-Host "  ✅ Firebase dependencies found in pubspec.yaml" -ForegroundColor Green
  }
  else {
    $warnings += "⚠️  Firebase: Not in pubspec.yaml"
  }
}
catch {
  $errors += "❌ pubspec.yaml: Cannot read"
}

# Check if pub get has been run
if (Test-Path "pubspec.lock") {
  $success += "✅ Dependencies: Installed"
  Write-Host "  ✅ pubspec.lock exists (flutter pub get was run)" -ForegroundColor Green
}
else {
  $warnings += "⚠️  Dependencies: Run 'flutter pub get'"
  Write-Host "  ⚠️  pubspec.lock not found - Run 'flutter pub get'" -ForegroundColor Yellow
}
Write-Host ""

# Check Git configuration
Write-Host "📌 Checking Git Configuration..." -ForegroundColor Yellow

if (Test-Path ".git") {
  $success += "✅ Git: Repository initialized"
  Write-Host "  ✅ Git repository found" -ForegroundColor Green
}
else {
  $warnings += "⚠️  Git: Not initialized"
}

if (Test-Path ".gitignore") {
  $gitignoreContent = Get-Content .gitignore
  if ($gitignoreContent -match "\.dart_tool") {
    $success += "✅ .gitignore: Configured"
    Write-Host "  ✅ .gitignore properly configured" -ForegroundColor Green
  }
  else {
    $warnings += "⚠️  .gitignore: May be incomplete"
  }
}
else {
  $warnings += "⚠️  .gitignore: Not found"
}
Write-Host ""

# Check VS Code configuration validity
Write-Host "⚙️  Validating VS Code Configuration..." -ForegroundColor Yellow

try {
  if (Test-Path "MixMingle.code-workspace") {
    $success += "✅ Workspace Configuration: Found"
    Write-Host "  ✅ MixMingle.code-workspace exists" -ForegroundColor Green
  }
  else {
    $errors += "❌ MixMingle.code-workspace: Not found"
  }

  if (Test-Path ".vscode/settings.json") {
    Get-Content ".vscode/settings.json" | ConvertFrom-Json -ErrorAction Stop | Out-Null
    $success += "✅ VS Code Settings: Valid JSON"
    Write-Host "  ✅ .vscode/settings.json is valid" -ForegroundColor Green
  }

  if (Test-Path ".vscode/launch.json") {
    $launchContent = Get-Content ".vscode/launch.json" | ConvertFrom-Json -ErrorAction Stop
    $configCount = $launchContent.configurations.Count
    $success += "✅ Launch Configurations: $configCount configured"
    Write-Host "  ✅ $configCount launch configurations found" -ForegroundColor Green
  }
}
catch {
  $errors += "❌ VS Code Configuration: Validation failed - $_"
}
Write-Host ""

# Summary
Write-Host "=" * 60
Write-Host "📊 Summary" -ForegroundColor Cyan
Write-Host "=" * 60
Write-Host "✅ Successes: $($success.Count)" -ForegroundColor Green
Write-Host "⚠️  Warnings: $($warnings.Count)" -ForegroundColor Yellow
Write-Host "❌ Errors: $($errors.Count)" -ForegroundColor Red
Write-Host ""

if ($success.Count -gt 0) {
  Write-Host "✅ Successes:" -ForegroundColor Green
  foreach ($msg in $success) {
    Write-Host "   $msg"
  }
  Write-Host ""
}

if ($warnings.Count -gt 0) {
  Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
  foreach ($msg in $warnings) {
    Write-Host "   $msg"
  }
  Write-Host ""
}

if ($errors.Count -gt 0) {
  Write-Host "❌ Errors (Must Fix):" -ForegroundColor Red
  foreach ($msg in $errors) {
    Write-Host "   $msg"
  }
  Write-Host ""
}

# Final status
Write-Host "=" * 60
if ($errors.Count -eq 0) {
  Write-Host "🎉 Configuration Valid!" -ForegroundColor Green
  Write-Host "Ready to start development!" -ForegroundColor Green
  exit 0
}
else {
  Write-Host "⚠️  Please fix the errors above before proceeding." -ForegroundColor Red
  exit 1
}
