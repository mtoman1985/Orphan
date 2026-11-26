@echo off
rem One-line installer: downloads the fixed scripts into this folder.
cd /d "%~dp0"
echo Downloading install.bat from GitHub...
curl.exe -fsSL -o "install.bat" "https://raw.githubusercontent.com/mtoman1985/Orphan/arena/d54fa983-orphan/clinic-bot/install.bat"
if errorlevel 1 goto FAIL
call install.bat
goto :eof
:FAIL
echo [X] Download failed. Open the link manually in your browser and save as install.bat
echo     https://github.com/mtoman1985/Orphan/blob/arena/d54fa983-orphan/clinic-bot/install.bat
pause
goto :eof
