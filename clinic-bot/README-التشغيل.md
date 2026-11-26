# 🦷 تشغيل بوت واتساب عيادة الأسنان على جهازك

هذا المجلد يحتوي بوت العيادة (`index.js`) — واتساب + MongoDB + Google Sheets + تقارير PDF.
الملفات الجاهزة هنا: `index.js`، `package.json`، `letterhead.jpeg` (ورقة العيادة)،
`credentials.json` و`token.json` (ربط Google)، `report_state.json`.

> ⚠️ **تنبيه أمان:** ملفات `.env` و`credentials.json` و`token.json` تحتوي أسراراً حقيقية
> (كلمة مرور قاعدة البيانات، مفتاح Gemini، توكن Google). **لا ترفعها إلى GitHub أبداً**
> — وهي مستثناة في `.gitignore` لهذا المجلد. إن سُرّبت يوماً، غيّر كلمة المرور والمفتاح فوراً.

---

## 1) المتطلبات

- **Node.js 18 أو أحدث** — حمّله من https://nodejs.org (اختر LTS)
- اتصال إنترنت مستقر (البوت يحتاج واتساب ويب + MongoDB Atlas + Google)
- على لينكس: مكتبات Chromium (مثبتة تلقائياً مع Puppeteer، وإن ظهر خطأ مكتبات مفقودة نفّذ):
  ```bash
  sudo apt install -y libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libgbm1 libasound2 libpangocairo-1.0-0 libxss1 libgtk-3-0
  ```

## 2) التجهيز (أول مرة فقط)

1. انسخ مجلد `clinic-bot` إلى جهازك.
2. أنشئ ملف `.env` من القالب:
   - ويندوز: `copy .env.example .env`
   - لينكس/ماك: `cp .env.example .env`
   ثم افتح `.env` واملأ:
   - `MONGODB_URI` — رابط قاعدة بيانات MongoDB Atlas
   - `GEMINI_API_KEY` — مفتاح Gemini
   - `WA_PAIR_PHONE` — رقم الهاتف بالصيغة الدولية بدون `+` (مثال: `972599331114`)
     اتركه فارغاً إن أردت الربط بالباركود QR بدلاً من كود الهاتف.
3. ثبّت الحزم:
   ```bash
   npm install
   ```

## 3) التشغيل

### تشغيل عادي (للتجربة)

- **ويندوز:** انقر نقراً مزدوجاً على `start-bot.bat`
- **لينكس/ماك:**
  ```bash
  chmod +x start-bot.sh
  ./start-bot.sh
  ```
  أو مباشرة: `npm start`

### تشغيل دائم (يعمل حتى بعد إغلاق النافذة / إعادة التشغيل) — عبر pm2

```bash
npm install -g pm2
pm2 start ecosystem.config.js
pm2 save
pm2 startup   # ليعمل تلقائياً بعد إعادة تشغيل الجهاز (اتبع التعليمات التي تظهر)
pm2 logs clinic-bot   # متابعة السجل
```

## 4) ربط واتساب (خطوة واحدة فقط)

بعد التشغيل افتح في المتصفح: **http://localhost:7861**

- إن كان `WA_PAIR_PHONE` مضبوطاً: ستظهر **كود ربط رقمي** — في هاتفك:
  واتساب ← الإعدادات ← الأجهزة المرتبطة ← ربط جهاز ← **الربط برقم الهاتف** ← اكتب الكود.
- وإلا: ستظهر **رمز QR** في صفحة `/qr` — امسحه من واتساب ← الأجهزة المرتبطة ← ربط جهاز.

بعد الربط ستظهر الحالة «✅ متصل وجاهز» وتبدأ التقارير والجداول الزمنية بالعمل تلقائياً.
الجلسة تُحفظ (MongoDB على لينكس/السيرفر، أو مجلد `.wwebjs_auth` على ويندوز) فلن تحتاج إعادة الربط.

## 5) ملاحظات مهمة

- **تصفير الجلسة:** إن علّقت الجلسة، ضع `RESET_WA_SESSION=1` في `.env` وشغّل مرة واحدة،
  ثم احذف السطر (أو ضع `0`) — وإلا سيُعاد التصفير عند كل تشغيل.
- **المنفذ:** الافتراضي `7861` — غيّره من `PORT` في `.env` إن كان مشغولاً.
- **إعادة ربط Google:** شغّل `node gmail-auth.js` وافتح `http://localhost:7860` وانسخ التوكن الجديد إلى `token.json`.
- **ملفات Hugging Face:** `app-huggingface.py` و`requirements-huggingface.txt` و`packages-huggingface.txt`
  خاصة بمنصة Hugging Face Spaces فقط — لا تحتاجها للتشغيل على جهازك.

## 6) استكشاف الأخطاء

| المشكلة | الحل |
|---|---|
| `Cannot find module ...` | نفّذ `npm install` داخل مجلد `clinic-bot` |
| خطأ Chromium / مكتبات مفقودة (لينكس) | ثبّت مكتبات Chromium كما في قسم 1 |
| `فشل الاتصال بـ MongoDB` / `querySrv EREFUSED` | السبب الأول: عنوان IP جهازك غير مسموح في Atlas. الحل: افتح [cloud.mongodb.com](https://cloud.mongodb.com) ← اختر المشروع ← **Network Access** ← **Add IP Address** ← **Allow Access From Anywhere** ← Confirm، انتظر دقيقتين ثم أعد تشغيل البوت. تحقق أيضاً أن الكلاستر غير موقوف مؤقتاً (Clusters ← Resume إن ظهر). للفحص السريع شغّل: `node check-connection.js` |
| `MONGODB_URI` غير مضبوط | أنشئ ملف `.env` من `.env.example` واملأ القيم ثم أعد التشغيل |
| البوت يعمل لكن لا يصل واتساب | تحقق من الإنترنت، ثم افتح `http://localhost:7861` لقراءة رسالة الخطأ |
| المنفذ مشغول | غيّر `PORT` في `.env` أو أوقف البرنامج الذي يستخدم 7861 |
