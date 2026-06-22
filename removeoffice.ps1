# 1. Definiera sökvägar och adresser
$WorkDir = "$env:SystemDrive\O365Cleanup"
$OdtUrl = "https://microsoft.com" # Kontrollera aktuell länk hos MS om nödvändigt
$OdtExe = "$WorkDir\odtsetup.exe"
$ConfigFile = "$WorkDir\remove_languages.xml"

# Skapa arbetsmapp om den inte finns
If (!(Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

# 2. Ladda ner och extrahera Office Deployment Tool (ODT)
Write-Host "Laddar ner Office Deployment Tool..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $OdtUrl -OutFile $OdtExe

Write-Host "Extraherar ODT-filer..." -ForegroundColor Cyan
Start-Process -FilePath $OdtExe -ArgumentList "/extract:`"$WorkDir`" /quiet" -Wait

# 3. Skapa XML-konfigurationsfilen för att rensa språk
# Vi anger <Remove All="False"> men definierar inga exkluderade produkter, 
# vilket gör att den rensar språkpaket som inte matchar det tillåtna språket (sv-se).
Write-Host "Skapar XML-konfigurationsfil..." -ForegroundColor Cyan
$XmlContent = @"
<Configuration>
    <Display Level="None" AcceptEULA="TRUE" />
    <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
    <Remove All="False">
        <Product ID="O365ProPlusRetail">
            <Language ID="MatchInstalled" />
        </Product>
    </Remove>
    <Add>
        <Product ID="O365ProPlusRetail">
            <Language ID="sv-se" />
        </Product>
    </Add>
</Configuration>
"@

$XmlContent | Out-File -FilePath $ConfigFile -Encoding UTF8 -Force

# 4. Kör ODT för att applicera ändringarna (tar bort övriga språk, behåller/säkerställer svenska)
Write-Host "Tar bort oönskade språkpaket (detta kan ta några minuter)..." -ForegroundColor Yellow
$Process = Start-Process -FilePath "$WorkDir\setup.exe" -ArgumentList "/configure `"$ConfigFile`"" -Wait -NoNewWindow -PassThru

# 5. Städa upp temporära filer
If ($Process.ExitCode -eq 0) {
    Write-Host "Klart! Alla språk utom svenska har tagits bort från Microsoft 365 Apps." -ForegroundColor Green
    Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
} Else {
    Write-Error "Något gick fel under körningen. ODT-felkod: $($Process.ExitCode)"
}
