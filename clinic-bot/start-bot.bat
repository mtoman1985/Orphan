@echo off
setlocal
cd /d "%~dp0"
title Clinic WhatsApp Bot
echo ==========================================
echo   Clinic WhatsApp Bot
echo ==========================================
echo.

where node >nul 2>nul
if errorlevel 1 goto NONODE

if not exist ".env" goto NOENV

findstr /R /C:"^MONGODB_URI=mongodb" ".env" >nul 2>nul
if errorlevel 1 goto NOURI

node -e "require('dotenv')" >nul 2>nul
if errorlevel 1 goto INSTALL

if not exist "node_modules\whatsapp-web.js" goto INSTALL

goto KILLPORT

:INSTALL
echo [i] Installing packages, this may take a few minutes...
call npm install --strict-ssl=false
echo.

:KILLPORT
set "FOUND="
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /C:"LISTENING" ^| findstr ":7861"') do (
  set "FOUND=1"
  echo [i] Closing old bot instance, PID %%a
  taskkill /F /PID %%a >nul 2>nul
)
if defined FOUND (
  timeout /t 2 /nobreak >nul
  echo [OK] Old instance closed.
  echo.
)

echo [i] Starting bot... open http://localhost:7861 in your browser
echo.
node index.js
echo.
echo [i] Bot stopped. Press any key to close this window.
pause >nul
goto :eof

:NONODE
echo [X] Node.js not found. Install it from https://nodejs.org
echo.
pause
goto :eof

:NOENV
echo [X] File .env not found in this folder:
echo     %~dp0
echo     Copy .env.example to .env and fill in the values.
echo.
pause
goto :eof

:NOURI
echo [X] MONGODB_URI is missing or empty in .env
echo     Open .env with Notepad and add one line like:
echo     MONGODB_URI=mongodb+srv://user:pass@cluster0.xxxxx.mongodb.net/
echo.
pause
goto :eof
