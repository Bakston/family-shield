@echo off
chcp 65001 >nul
echo ==========================================
echo    Сборка релизного APK для Family Shield
echo ==========================================

:: Запускаем полный цикл в PowerShell (увеличение версии, очистка, pub get и build)
powershell -ExecutionPolicy Bypass -File "build_release.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ОШИБКА] Процесс сборки завершился с ошибкой!
    pause
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo Все задачи успешно выполнены!
echo APK-файл находится в:
echo android\app\build\outputs\flutter-apk\app-release.apk
echo ==========================================
pause