#!/usr/bin/env bash
# تشغيل بوت عيادة الأسنان على لينكس / ماك
set -e
cd "$(dirname "$0")"

echo "🦷 بوت عيادة الأسنان — جاري التجهيز..."

if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js غير مثبت. ثبّته من https://nodejs.org (الإصدار 18 أو أحدث) ثم أعد المحاولة."
  exit 1
fi

if [ ! -f .env ]; then
  echo "❌ ملف .env غير موجود. انسخ .env.example إلى .env واملأ القيم ثم أعد المحاولة."
  exit 1
fi

if [ ! -d node_modules ]; then
  echo "📦 تثبيت الحزم (قد يستغرق عدة دقائق أول مرة)..."
  npm install
fi

echo "🚀 تشغيل البوت على المنفذ ${PORT:-7861} ..."
echo "   افتح http://localhost:7861 لمتابعة الحالة ومسح رمز QR / كود الربط"
exec node index.js
