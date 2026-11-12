$ErrorActionPreference = "Stop"

$pubspecPath = "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Host "[ERROR] pubspec.yaml not found!" -ForegroundColor Red
    exit 1
}

$content = [System.IO.File]::ReadAllText((Resolve-Path $pubspecPath))

if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = $Matches[1]
    $minor = $Matches[2]
    # Increment both patch and buildCode so the tag (vX.Y.Z) is always new
    $patch = [int]$Matches[3] + 1
    $buildCode = [int]$Matches[4] + 1
    
    $oldVersionString = $Matches[0]
    $newVersionString = "version: $major.$minor.$patch+$buildCode"
    $tagName = "v$major.$minor.$patch"
    
    $content = $content.Replace($oldVersionString, $newVersionString)
    [System.IO.File]::WriteAllText((Resolve-Path $pubspecPath), $content)
    Write-Host "[SUCCESS] Version updated to: $newVersionString (Tag: $tagName)" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Could not find version format in pubspec.yaml!" -ForegroundColor Red
    exit 1
}

Write-Host "[1/5] Cleaning project cache..." -ForegroundColor Cyan
flutter clean
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[2/5] Getting dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "[3/5] Building release APK (with --no-tree-shake-icons)..." -ForegroundColor Cyan
flutter build apk --release --no-tree-shake-icons
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    $apkPath = "android\app\build\outputs\flutter-apk\app-release.apk"
}

if (-not (Test-Path $apkPath)) {
    Write-Host "[ERROR] Built APK not found!" -ForegroundColor Red
    exit 1
}

Write-Host "[4/5] Committing, updating tags, and pushing to Git..." -ForegroundColor Cyan
git add pubspec.yaml
git commit -m "chore: release $tagName+$buildCode"
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Git push failed or no upstream branch set." -ForegroundColor Yellow
}

# Удаляем локальный тег (если существовал), создаем заново и отправляем на origin
git tag -d $tagName 2>$null
git tag $tagName
git push origin $tagName --force
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Failed to push git tag to origin." -ForegroundColor Yellow
}

Write-Host "[5/5] Creating GitHub Release $tagName and uploading APK..." -ForegroundColor Cyan
gh release create $tagName $apkPath --title "Release $tagName" --notes "Automated release $tagName (build $buildCode)"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create GitHub release!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[DONE] Release $tagName successfully published to GitHub with APK!" -ForegroundColor Green