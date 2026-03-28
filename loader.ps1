try {
    $path = "$env:TEMP\run.bat"

    @"
@echo off
title C:\Windows\System32\conhost.exe
cls

echo CMD STARTED
pause
"@ | Out-File -Encoding ASCII $path

    cmd.exe /k "$path"
}
catch {
    # ปิด error ทั้งหมด
}

exit
