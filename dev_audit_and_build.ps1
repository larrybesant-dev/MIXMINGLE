Write-Host "==============================="
Write-Host " FULL ENVIRONMENT AUDIT START "
Write-Host "==============================="

# ---- BASIC CONTEXT ----
Write-Host "`n[Project Directory]"
Get-Location

# ---- TOOLCHAIN CHECK ----
Write-Host "`n[Flutter]"
flutter --version

Write-Host "`n[Java]"
java -version

Write-Host "`n[Gradle Wrapper]"
if (Test-Path ".\android\gradlew") {
    cd android
    .\gradlew -v
    cd ..
} else {
    Write-Host "❌ gradlew NOT FOUND"
}

# ---- FLUTTER DOCTOR ----
Write-Host "`n[Flutter Doctor]"
flutter doctor -v

# ---- PROJECT STRUCTURE CHECK ----
Write-Host "`n[Project Structure]"
$required = @(
    "lib\main.dart",
    "pubspec.yaml",
    "android\build.gradle",
    "android\app\build.gradle"
)

foreach ($file in $required) {
    if (Test-Path $file) {
        Write-Host "✅ $file"
    } else {
        Write-Host "❌ MISSING: $file"
    }
}

# ---- HARD CLEAN ----
Write-Host "`n[Hard Clean]"
flutter clean
Remove-Item -Recurse -Force .dart_tool, build -ErrorAction SilentlyContinue

if (Test-Path "android") {
    cd android
    .\gradlew clean
    cd ..
}

# ---- DEPENDENCIES ----
Write-Host "`n[Pub Get]"
flutter pub get

# ---- ANALYZE ----
Write-Host "`n[Flutter Analyze]"
flutter analyze

# ---- BUILD TARGETS ----
Write-Host "`n[Web Build]"
flutter build web --release

Write-Host "`n[Android Debug APK]"
flutter build apk --debug

Write-Host "`n[Android Release Bundle]"
flutter build appbundle --release

Write-Host "`n==============================="
Write-Host " AUDIT & BUILD COMPLETE "
Write-Host "==============================="
