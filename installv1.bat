@echo off
:: ==============================================================================
:: BATCH-SKRIPT FÖR APPLIKATIONSINSTALLATION OCH KONFIGURATION (LOKAL DATOR)
:: ==============================================================================
chcp 65001 >nul
echo Söker efter administratörsrättigheter...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [FEL] Detta skript MÅSTE köras som administratör!
    echo Högerklicka på filen och välj "Kör som administratör".
    pause
    exit /b
)

:: ==============================================================================
:: 1. KONTROLLERA ATT WINGET FINNS OCH FUNGERAR
:: ==============================================================================
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

:: ==============================================================================
:: 2. INSTALLERA CHROME OCH ACROBAT READER
:: ==============================================================================
echo.
echo Installerar Google Chrome...
winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements

echo Installerar Adobe Acrobat Reader...
winget install --id Adobe.Acrobat.Reader.64bit --silent --accept-source-agreements --accept-package-agreements

:: ==============================================================================
:: 3. TA BORT UTDRAG AV SPRÅKPAKET FÖR M365 & ONENOTE VIA POWERSHELL-ANROP
:: ==============================================================================
echo.
echo Rensar språkpaket för Microsoft 365 och OneNote (behåller sv-se)...
:: Eftersom batch inte kan loopa registret effektivt anropas en snabb inline PowerShell-rad
powershell -NoProfile -Command ^
    "$O365Reg = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration';" ^
    "if (Test-Path $O365Reg) {" ^
    "  $langs = (Get-ItemProperty $O365Reg).ProductReleaseCultures -split ',';" ^
    "  $rem = ($langs | Where-Object { $_ -ne 'sv-se' -and $_ -ne '' }) -join ',';" ^
    "  if ($rem) {" ^
    "    New-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Updates' -Name 'VersionedCulturesToRemoveAsCSV' -Value $rem -Force | Out-Null;" ^
    "    $c2r = \"$env:CommonProgramFiles\Microsoft Shared\ClickToRun\OfficeC2RClient.exe\";" ^
    "    if (Test-Path $c2r) { Start-Process $c2r -ArgumentList '/update user displaylevel=false forceappshutdown=true' -Wait }" ^
    "  }" ^
    "}"
    
:: Tar bort Windows Store/UWP-språkvarianter för OneNote
powershell -NoProfile -Command "Get-AppxPackage -AllUsers | Where-Name { $_.Name -like '*OneNote*' -and $_.Language -ne '' -and $_.Language -ne 'sv-SE' } | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue"

:: ==============================================================================
:: 4. KONFIGURERA MICROSOFT EDGE VIA LOKALT REGISTER (INGEN DOMÄN KRÄVS)
:: ==============================================================================
echo.
echo Konfigurerar inställningar för Microsoft Edge (Google som start/sök)...

set "EdgePolicy=HKLM\SOFTWARE\Policies\Microsoft\Edge"

:: Sätt startsida (RestoreOnStartup 4 = Öppna specifika URL-er)
reg add "%EdgePolicy%" /v RestoreOnStartup /t REG_DWORD /d 4 /f >nul
reg add "%EdgePolicy%" /v HomepageLocation /t REG_SZ /d "https://google.se" /f >nul
reg add "%EdgePolicy%\RestoreOnStartupURLs" /v "1" /t REG_SZ /d "https://google.se" /f >nul

:: Sätt standardsökmotor till Google
reg add "%EdgePolicy%" /v DefaultSearchProviderEnabled /t REG_DWORD /d 1 /f >nul
reg add "%EdgePolicy%" /v DefaultSearchProviderName /t REG_SZ /d "Google" /f >nul
reg add "%EdgePolicy%" /v DefaultSearchProviderSearchURL /t REG_SZ /d "https://google.se/search?q={searchTerms}" /f >nul

echo [OK] Edge-inställningarna har tillämpats lokalt på datorn.
echo.
echo Skriptet har slutförts!
pause
