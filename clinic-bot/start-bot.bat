@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d %~dp0
echo ==========================================
echo   بوت عيادة الأسنان - تشغيل
echo ==========================================
echo.

where node >nul 2>nul
if errorlevel 1 (
  echo [X] Node.js غير مثبت. حمّله من https://nodejs.org ثم أعد المحاولة.
  pause
  exit /b 1
)

if not exist .env (
  echo [X] ملف .env غير موجود.
  echo     انسخ .env.example وسمّه .env ثم املأ القيم بداخله.
  pause
  exit /b 1
)

rem --- إغلاق أي نسخة قديمة تعمل على المنفذ 7861 ---
set FOUND=
for /f "tokens=5" %%a in ('netstat -ano ^| findstr /R /C:"LISTENING" ^| findstr ":7861"') do (
  set FOUND=1
  echo [i] إغلاق نسخة قديمة من البوت (PID %%a)...
  taskkill /F /PID %%a >nul 2>nul
)
if defined FOUND (
  timeout /t 2 /nobreak >nul
  echo [OK] تم إغلاق النسخة القديمة.
  echo.
)

if not exist node_modules (
  echo [i] تثبيت الحزم (قد يستغرق عدة دقائق أول مرة)...
  call npm install
  echo.
)

echo [i] تشغيل البوت... افتح المتصفح على: http://localhost:7861
echo.
node index.js

echo.
echo [i] توقف البوت. اضغط أي زر للإغلاق.
pause >nul
