#
# Detta skript gör följande i tur och ordning
# 1. Installerar Google Chrome
# 2. Installerar Acrobat Reader
# 3. Avinstallerar alla Office paket som INTE är svenska
#
# För att köra detta på en nyinstallerad dator så måste du starta Kommandotolken(CMD) eller Powershell (helst) som administratör och sedan skriva:
# powershell -ExecutionPolicy Bypass -File "install.ps1"
@echo off
echo Installerar Google Chrome...
winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements --source winget

echo Installerar Adobe Acrobat Reader...
winget install --id Adobe.Acrobat.Reader.64-bit --silent --accept-source-agreements --accept-package-agreements --source winget

echo Avinstallerar Office for buiseness (ej sv-se)
# Sökvägar i registret där Office-komponenter listas
$RegistryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Sök efter alla registerposter som tillhör Office ClickToRun och inte är svenska
$OfficeComponents = Get-ItemProperty $RegistryPaths | Where-Object {
    ($_.DisplayName -like "*Microsoft 365*" -or $_.UninstallString -like "*OfficeClickToRun.exe*") -and
    $_.DisplayName -notlike "*sv-se*" -and
    $_.UninstallString -notlike "*culture=sv-se*"
}

if ($OfficeComponents) {
    foreach ($Comp in $OfficeComponents) {
        Write-Host "Hittade komponent: $($Comp.DisplayName)" -ForegroundColor Cyan
        
        # Sökvägen till avinstalleraren är alltid densamma för ClickToRun
        $C2RPath = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
        
        if (Test-Path $C2RPath) {
            # Extrahera eller bygg argumenten baserat på vad som finns i registret
            if ($Comp.UninstallString -match 'productstoremove=([^ ]+)') {
                $ProductToRemove = $Matches[1]
                # Kontrollera extra noga så vi inte avinstallerar sv-se av misstag
                if ($ProductToRemove -like "*sv-se*") { continue }
                
                # Bygg de korrekta, dolda argumenten för just detta språkpaket
                $Arguments = "scenario=install scenariosubtype=uninstall sourcetype=None productstoremove=$ProductToRemove DisplayLevel=False forceappshutdown=True"
            } else {
                # Fallback om strängen ser annorlunda ut
                $Arguments = "scenario=install scenariosubtype=uninstall productreleaseid=O365ProPlusRetail DisplayLevel=False forceappshutdown=True"
            }

            Write-Host "Avinstallerar språkversion med argument: $Arguments" -ForegroundColor Yellow
            
            # Starta den tysta avinstallationen och vänta tills den är helt klar
            $Process = Start-Process -FilePath $C2RPath -ArgumentList $Arguments -Wait -NoNewWindow -PassThru
            
            if ($Process.ExitCode -eq 0) {
                Write-Host "Borttagning lyckades!" -ForegroundColor Green
            } else {
                Write-Host "Avinstallationen avslutades med kod: $($Process.ExitCode)" -ForegroundColor Red
            }
        } else {
            Write-Host "Kunde inte hitta OfficeClickToRun.exe på standardplatsen." -ForegroundColor Red
        }
    }
} else {
    Write-Host "Inga utländska Office-komponenter eller språkpaket hittades." -ForegroundColor Yellow
}
