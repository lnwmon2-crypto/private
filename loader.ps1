$Host.UI.RawUI.WindowTitle = "C:\Windows\System32\conhost.exe"
Clear-Host

===== เปิด ConsoleHost_history.txt =====
$hist = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
if (!(Test-Path $hist)) {
    New-Item -ItemType File -Path $hist -Force | Out-Null
}
Start-Process notepad.exe $hist

===== KEY LIST =====
$keys = @(
"finalpremium-27BHJ",
"finalpremium-8K2LM",
"finalpremium-X91QP",
"finalpremium-55TGH",
"finalpremium-AB12Z",
"finalpremium-9PLK3",
"finalpremium-QW77E",
"finalpremium-ZX90N",
"finalpremium-MN45R",
"finalpremium-LL22X",
"Nel",
"King"
)

===== รับ key =====
$key = Read-Host "Enter license key"

===== เช็ค key =====
if ($keys -contains $key) {

    # โหลด main.ps1 แบบเสถียร
    $script = (iwr "https://raw.githubusercontent.com/USER/rmt-check/main/main.ps1").Content
    iex $script

    Write-Host ""
    Write-Host "Successfully" -ForegroundColor Green
}
else {
    Write-Host "[!] Invalid key." -ForegroundColor Red
}
