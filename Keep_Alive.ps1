$wscript = New-Object -ComObject Wscript.Shell
Write-Host "Skriptet körs... Tryck Ctrl+C i detta fönster för att stänga av." -ForegroundColor Green

while ($true) {
    # Trycker på Scroll Lock två gånger (slås på och av direkt) var 240:e sekund
    $wscript.SendKeys("{SCROLLLOCK}")
    Start-Sleep -Milliseconds 100
    $wscript.SendKeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 110
}
