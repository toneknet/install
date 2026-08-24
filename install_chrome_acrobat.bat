rem @echo off
rem ==============================================================================
rem BATCH-SKRIPT FÖR APPLIKATIONSINSTALLATION OCH KONFIGURATION (LOKAL DATOR)
rem ==============================================================================
chcp 65001 >nul
echo Söker efter administratörsrättigheter...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [FEL] Detta skript MÅSTE köras som administratör!
    echo Högerklicka på filen och välj "Kör som administratör".
    pause
    exit /b
)

rem ==============================================================================
rem 1. KONTROLLERA ATT WINGET FINNS OCH FUNGERAR
rem ==============================================================================
echo.
echo Kontrollerar Winget...
where winget >nul 2>&1
if %errorLevel% neq 0 (
    echo [FEL] Winget hittades inte på systemet. Skriptet avbryts.
    pause
    exit /b
)

winget --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [FEL] Winget finns installerat men fungerar inte korrekt. Skriptet avbryts.
    pause
    exit /b
)
echo [OK] Winget fungerar korrekt.

rem ==============================================================================
rem 2. INSTALLERA CHROME OCH ACROBAT READER
rem ==============================================================================
echo.
echo Installerar Google Chrome...
winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements --source winget

echo Installerar Adobe Acrobat Reader...
winget install --id Adobe.Acrobat.Reader.64-bit --silent --accept-source-agreements --accept-package-agreements --source winget
