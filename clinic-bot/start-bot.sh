#!/usr/bin/env bash
# تشغيل بوت عيادة الأسنان على لينكس / ماك
cd "$(dirname "$0")"

PORT_TO_USE="${PORT:-7861}"

echo "=========================================="
echo "  بوت عيادة الأسنان - تشغيل"
echo "=========================================="

if ! command -v node >/dev/null 2>&1; then
  echo "❌ Node.js غير مثبت. حمّله من https://nodejs.org (الإصدار 18 أو أحدث)."
  exit 1
fi

if [ ! -f .env ]; then
  echo "❌ ملف .env غير موجود. انسخ .env.example إلى .env واملأ القيم ثم أعد المحاولة."
  exit 1
fi

# إغلاق أي نسخة قديمة تستخدم نفس المنفذ
OLD_PIDS=$(lsof -ti :"$PORT_TO_USE" 2>/dev/null || true)
if [ -n "$OLD_PIDS" ]; then
  echo "ℹ️ إغلاق نسخة قديمة من البوت (PID: $OLD_PIDS)..."
  echo "$OLD_PIDS" | xargs -r kill -9 2>/dev/null || true
  sleep 1
fi

if [ ! -d node_modules ]; then
  echo "📦 تثبيت الحزم (قد يستغرق عدة دقائق أول مرة)..."
  npm install
fi

echo "🚀 تشغيل البوت على المنفذ $PORT_TO_USE"
echo "   افتح http://localhost:$PORT_TO_USE لمتابعة الحالة وكود الربط"
echo ""
exec node index.js
