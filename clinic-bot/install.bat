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
  echo     Created empty .env in this folder.
) else (
  echo [3/5] .env found - keeping your settings.
)
echo.

call :CHECKENV
if not errorlevel 1 goto ENVREADY

echo     MONGODB_URI is empty. Opening .env in Notepad.
echo     Fill in the line MONGODB_URI=... then SAVE (Ctrl+S) and CLOSE Notepad.
echo.
notepad ".env"
call :CHECKENV
if not errorlevel 1 goto ENVREADY
echo.
echo [X] MONGODB_URI is still empty in %~dp0.env
echo     Open the file with Notepad and add one line, for example:
echo     MONGODB_URI=mongodb+srv://user:password@cluster0.xxxxx.mongodb.net/
echo     Save the file, then run start-bot.bat again.
echo.
pause
goto :eof

:ENVREADY
echo     MONGODB_URI looks OK.
echo.

echo [4/5] Installing packages, please wait (a few minutes)...
call npm install --strict-ssl=false
echo.
echo     Note: the "npm warn ... install-scripts" lines are harmless.
echo.

if exist "%USERPROFILE%\.cache\puppeteer" goto CHROMEOK
if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" goto CHROMEOK
echo     Downloading Chrome for WhatsApp Web (about 150 MB, once only)...
call npx --yes puppeteer browsers install chrome
echo.
:CHROMEOK
echo     Browser is ready.
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

:CHECKENV
rem returns 0 when .env has a non-empty MONGODB_URI
findstr /R /C:"^MONGODB_URI=mongodb" ".env" >nul 2>nul
if errorlevel 1 exit /b 1
exit /b 0

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
