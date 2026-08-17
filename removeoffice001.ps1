# Definiera sökvägar i registret där installerade program listas
$RegistryPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Sök efter alla Office-paket som inte är sv-se
$OfficeApps = Get-ItemProperty $RegistryPaths | Where-Object {
    $_.DisplayName -like "*Microsoft 365 Apps for enterprise*" -and 
    $_.DisplayName -notlike "*sv-se*" -and
    $_.UninstallString -like "*OfficeC2RClient.exe*"
}

if ($OfficeApps) {
    foreach ($App in $OfficeApps) {
        Write-Host "Avinstallerar språkversion: $($App.DisplayName)" -ForegroundColor Cyan
        
        # Extrahera sökvägen till OfficeC2RClient.exe från registersträngen
        if ($App.UninstallString -match '"([^"]+)"') {
            $C2RClientPath = $Matches[1]
        } else {
            $C2RClientPath = $App.UninstallString.Split(" ")[0]
        }

        # Skapa tysta argument för ClickToRun-avinstalleraren
        $Arguments = "scenario=install scenariosubtype=uninstall productreleaseid=O365ProPlusRetail displaylevel=False forceappshutdown=True"
        
        # Om registret innehåller ett specifikt språk-ID (t.ex. en-us, fr-fr), lägg till det
        if ($App.PSChildName -match 'O365ProPlusRetail - (\w{2}-\w{2})') {
            $Lang = $Matches[1]
            $Arguments += " culture=$Lang"
        }

        # Starta avinstallationen i bakgrunden och vänta tills den är klar
        Start-Process -FilePath $C2RClientPath -ArgumentList $Arguments -Wait -NoNewWindow
        Write-Host "Klar med avinstallationen för denna språkversion." -ForegroundColor Green
    }
} else {
    Write-Host "Inga utländska språkversioner av Microsoft 365 Apps for enterprise hittades." -ForegroundColor Yellow
}
