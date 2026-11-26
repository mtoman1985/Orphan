@echo off
setlocal
title Clinic Bot - Update and Run
cd /d "%~dp0"

echo ==========================================
echo   Clinic WhatsApp Bot - update and run
echo ==========================================
echo   Folder: %~dp0
echo.

where node >nul 2>nul
if errorlevel 1 goto NONODE

set "BASE=https://raw.githubusercontent.com/mtoman1985/Orphan/arena/d54fa983-orphan/clinic-bot"
set "FAIL="

echo [1/5] Downloading latest files from GitHub...
call :DL index.js
call :DL package.json
call :DL start-bot.bat
call :DL check-connection.js
call :DL install.bat
if defined FAIL goto DLFAIL
echo     Done.
echo.

echo [2/5] Closing old bot and pm2 instances...
taskkill /F /IM node.exe >nul 2>nul
where pm2 >nul 2>nul
if not errorlevel 1 call pm2 delete all >nul 2>nul
timeout /t 1 /nobreak >nul
echo     Done.
echo.

if not exist ".env" (
  echo [3/5] .env not found - creating it now...
  > ".env" echo PORT=7861
  >> ".env" echo MONGODB_URI=
  >> ".env" echo GEMINI_API_KEY=
  >> ".env" echo WA_PAIR_PHONE=
  >> ".env" echo RESET_WA_SESSION=0
  echo     Created. Opening Notepad - fill in MONGODB_URI then save and close.
  notepad ".env"
) else (
  echo [3/5] .env found - keeping your settings.
)
echo.

echo [4/5] Installing packages, please wait (a few minutes)...
call npm install --strict-ssl=false
echo.
echo     Note: the "npm warn ... install-scripts" lines are harmless.
echo.

echo [5/5] Starting the bot...
echo     Open http://localhost:7861 in your browser.
echo     Keep this window open. Press Ctrl+C to stop.
echo.
node index.js
echo.
echo Bot stopped. Press any key to close.
pause >nul
goto :eof

:DL
echo     - %1
curl.exe -fsSL -o "%1" "%BASE%/%1"
if errorlevel 1 set "FAIL=1"
goto :eof

:NONODE
echo [X] Node.js not found. Install it from https://nodejs.org then run this file again.
echo.
pause
goto :eof

:DLFAIL
echo.
echo [X] Download failed. Your network may block raw.githubusercontent.com.
echo     Alternative: open https://github.com/mtoman1985/Orphan/tree/arena/d54fa983-orphan/clinic-bot
echo     and download index.js / package.json manually with the download button.
echo.
pause
goto :eof
