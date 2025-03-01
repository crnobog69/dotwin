@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0\Windows_Cleanup.ps1"
echo.
echo Cleanup complete! Press any key to exit...
pause >nul
