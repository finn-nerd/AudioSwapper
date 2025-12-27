@echo off
SETLOCAL

REM === Path to your compiled EXE ===
set "AppPath=%~dp0AudioSwapper.exe"

REM === Get the current user's Startup folder ===
set "StartupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

REM === Shortcut path ===
set "ShortcutPath=%StartupFolder%\AudioSwapper.lnk"

REM === Create shortcut using PowerShell (single line) ===
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%ShortcutPath%'); $Shortcut.TargetPath = '%AppPath%'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.Save()"

echo Shortcut created in Startup folder.
echo AudioSwapper.exe will now start on computer startup.
echo See startup programs with Win+R --^> shell:startup.
pause
ENDLOCAL
