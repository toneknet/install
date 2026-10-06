#
# Detta skript gör följande i tur och ordning
# 1. Installerar Google Chrome
# 2. Installerar Acrobat Reader
# 3. Avinstallerar alla Office paket som INTE är svenska
# 4. Installerar office classic OM filen officesetup.exe finns i samma mapp
#
# För att köra detta på en nyinstallerad dator så måste du starta Kommandotolken(CMD) eller Powershell (helst) som administratör och sedan skriva:
# powershell -ExecutionPolicy Bypass -File ".\install.ps1"
#@echo off
Write-Host "Installerar Google Chrome..." -ForegroundColor DarkGreen
winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements --source winget

Write-Host "Installerar Adobe Acrobat Reader..." -ForegroundColor DarkGreen
winget install --id Adobe.Acrobat.Reader.64-bit --silent --accept-source-agreements --accept-package-agreements --source winget

Write-Host "Avinstallerar Office for buiseness (ej sv-se)" -ForegroundColor DarkGreen
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


# Kan tanka ner office här (SVENSK CLASSIC)
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2276500&clcid=0x41d" -OutFile "officesetup.exe"
#Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?linkid=2276500&clcid=0x41d" -Destination "officesetup.exe"

# Ange namnet på filen du letar efter
$installer = ".\officesetup.exe"

# Kontrollera om filen finns
if (Test-Path -Path $installer) {
# Fixa configuration.xml
$xmlContent = @"
<Display Level="None" AcceptEULA="TRUE" />
"@
    $xmlContent | Out-File -FilePath ".\configuration.xml" -Encoding utf8
    
    Write-Host "Installationsfilen hittades. Startar installationen..." -ForegroundColor Green
    
    # Kör installationen och vänta tills den är klar
    Start-Process -FilePath $installer -ArgumentList "/configure configuration.xml" -Wait -NoNewWindow

    # 4. Städa bort configuration.xml efteråt
    if (Test-Path -Path ".\configuration.xml") {
        Remove-Item -Path ".\configuration.xml" -Force
        Write-Host "configuration.xml har tagits bort." -ForegroundColor Green
    }
    
    Write-Host "Installationen har slutförts." -ForegroundColor Green
} else {
    Write-Warning "Fel: Hittade inte filen $installer i den aktuella mappen."
}
