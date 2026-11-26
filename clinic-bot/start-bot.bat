@echo off
chcp 65001 >nul
cd /d %~dp0
echo 🦷 بوت عيادة الأسنان — جاري التجهيز...

where node >nul 2>nul
if errorlevel 1 (
  echo ❌ Node.js غير مثبت. ثبّته من https://nodejs.org (الإصدار 18 أو أحدث) ثم أعد المحاولة.
  pause
  exit /b 1
)

if not exist .env (
  echo ❌ ملف .env غير موجود. انسخ .env.example إلى .env واملأ القيم ثم أعد المحاولة.
  pause
  exit /b 1
)

if not exist node_modules (
  echo 📦 تثبيت الحزم (قد يستغرق عدة دقائق أول مرة)...
  call npm install
)

echo 🚀 تشغيل البوت على المنفذ 7861 ...
echo    افتح http://localhost:7861 لمتابعة الحالة ومسح رمز QR / كود الربط
node index.js
pause
