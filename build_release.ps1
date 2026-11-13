$ErrorActionPreference = "Stop"

$pubspecPath = "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Host "[ERROR] pubspec.yaml not found!" -ForegroundColor Red
    exit 1
}

$resolvedPubspec = (Resolve-Path $pubspecPath).Path
$originalContent = [System.IO.File]::ReadAllText($resolvedPubspec)

if ($originalContent -match 'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)') {
    $major = $Matches[1]
    $minor = $Matches[2]
    $patch = [int]$Matches[3] + 1
    $buildCode = [int]$Matches[4] + 1
    
    $oldVersionString = $Matches[0]
    $newVersionString = "version: $major.$minor.$patch+$buildCode"
    $tagName = "v$major.$minor.$patch"
} else {
    Write-Host "[ERROR] Could not find version format in pubspec.yaml!" -ForegroundColor Red
    exit 1
}

# Обновляем pubspec.yaml ДО сборки, чтобы новая версия зашилась в APK
$updatedContent = $originalContent.Replace($oldVersionString, $newVersionString)
[System.IO.File]::WriteAllText($resolvedPubspec, $updatedContent)
Write-Host "[INFO] Target release: $newVersionString (Tag: $tagName)" -ForegroundColor Cyan

try {
    Write-Host "[1/5] Cleaning project cache..." -ForegroundColor Cyan
    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "flutter clean failed" }

    Write-Host "[2/5] Getting dependencies..." -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

    Write-Host "[3/5] Building release APK (with --no-tree-shake-icons)..." -ForegroundColor Cyan
    flutter build apk --release --no-tree-shake-icons
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed" }

    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkPath)) {
        $apkPath = "android\app\build\outputs\flutter-apk\app-release.apk"
    }

    if (-not (Test-Path $apkPath)) {
        throw "Built APK not found!"
    }

    Write-Host "[4/5] Committing, updating tags, and pushing to Git..." -ForegroundColor Cyan
    git add pubspec.yaml
    git commit -m "chore: release $tagName+$buildCode"

    $ErrorActionPreference = "Continue"
    git push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARNING] Git push failed or no upstream branch set." -ForegroundColor Yellow
    }

    $existingTag = git tag -l $tagName
    if ($existingTag) {
        git tag -d $tagName 2>$null | Out-Null
    }
    $ErrorActionPreference = "Stop"

    git tag $tagName
    git push origin $tagName --force
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to push git tag $tagName to origin!"
    }

    Write-Host "[5/5] Creating GitHub Release $tagName and uploading APK..." -ForegroundColor Cyan
    $ErrorActionPreference = "Continue"
    gh release view $tagName >$null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[INFO] Release $tagName already exists on GitHub. Recreating..." -ForegroundColor Yellow
        gh release delete $tagName --yes
    }
    $ErrorActionPreference = "Stop"

    gh release create $tagName $apkPath --title "Release $tagName" --notes "Automated release $tagName (build $buildCode)"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create GitHub release!"
    }

    Write-Host "[DONE] Release $tagName successfully published to GitHub with APK!" -ForegroundColor Green
}
catch {
    # При любой ошибке возвращаем pubspec.yaml в исходное состояние
    [System.IO.File]::WriteAllText($resolvedPubspec, $originalContent)
    Write-Host "[ROLLBACK] Restored pubspec.yaml due to error: $_" -ForegroundColor Yellow
    exit 1
}