// أداة فحص شاملة: هل جهازك يستطيع الوصول إلى MongoDB Atlas؟
// التشغيل: node check-connection.js
let dotenvOk = true;
try { require('dotenv').config({ path: require('path').join(__dirname, '.env') }); } catch (e) { dotenvOk = false; }

const fs = require('fs');
const path = require('path');
const dns = require('dns');
const net = require('net');

const ok = (s) => console.log('✅ ' + s);
const bad = (s) => console.log('❌ ' + s);
const info = (s) => console.log('   ' + s);

console.log('==========================================');
console.log('  فحص اتصال بوت العيادة بقاعدة البيانات');
console.log('==========================================\n');

// ---------- 1) ملف .env ----------
const envPath = path.join(__dirname, '.env');
if (!fs.existsSync(envPath)) {
    bad('ملف .env غير موجود بجانب index.js');
    info('الحل: انسخ .env.example إلى .env واملأ القيم (مسار الملف يجب أن يكون: ' + envPath + ')');
    process.exit(1);
}
ok('ملف .env موجود: ' + envPath);
if (!dotenvOk) {
    bad('حزمة dotenv غير مثبتة — البوت لن يستطيع قراءة .env');
    info('الحل: نفّذ npm install داخل مجلد clinic-bot');
    process.exit(1);
}

const uri = (process.env.MONGODB_URI || process.env.MONGO_URI || '').trim();
if (!uri) {
    bad('MONGODB_URI غير موجود داخل .env أو قيمته فارغة');
    info('افتح .env وتأكد من سطر بالشكل: MONGODB_URI=mongodb+srv://user:pass@cluster0.xxxxx.mongodb.net/...');
    process.exit(1);
}
if (/^["']|["']$/.test(uri)) {
    bad('قيمة MONGODB_URI محاطة بعلامات تنصيص — احذف علامات " أو \' من حول الرابط');
}
if (/\s/.test(uri)) {
    bad('قيمة MONGODB_URI تحتوي مسافات أو سطراً زائداً — يجب أن تكون في سطر واحد بلا مسافات');
}
ok('تم قراءة MONGODB_URI (الطول: ' + uri.length + ' حرفاً)');

// ---------- 2) استخراج اسم الخادم ----------
const isSrv = uri.startsWith('mongodb+srv://');
const m = uri.match(/^mongodb(\+srv)?:\/\/(?:[^@/]*@)?([^/?]+)/);
const host = m ? m[2].split(',')[0] : '';
if (!host) {
    bad('تعذّر قراءة اسم الخادم من الرابط — تحقق من صيغة MONGODB_URI');
    process.exit(1);
}
ok('نوع الاتصال: ' + (isSrv ? 'mongodb+srv (يحتاج سجلات SRV)' : 'mongodb (مباشر)'));
ok('الخادم: ' + host);

const port = 27017;
let failures = 0;

// ---------- 3) فحص سجلات SRV ----------
function checkSrv() {
    return new Promise((resolve) => {
        if (!isSrv) return resolve(null);
        dns.resolveSrv('_mongodb._tcp.' + host, (err, recs) => {
            if (err) {
                failures++;
                bad('فشل استعلام SRV: ' + err.code);
                info('هذه هي المشكلة: شبكتك لا تسمح باستعلامات SRV التي يحتاجها MongoDB Atlas.');
                info('الحلول بالترتيب:');
                info('  1) غيّر DNS النظام إلى 8.8.8.8 و 8.8.4.4 ثم نفّذ: ipconfig /flushdns');
                info('  2) جرّب الاتصال عبر هوت سبوت الجوال — إن نجح فالمشكلة في شبكة الإنترنت/الراوتر');
                info('  3) استخدم الرابط المباشر: في Atlas اضغط Connect ← Drivers ← اختر إصداراً قديماً من Node.js');
                info('     لتحصل على رابط mongodb:// (بدون srv) وضعه في MONGODB_URI بدل الرابط الحالي');
                resolve(null);
                return;
            }
            ok('سجلات SRV تعمل — خوادم القاعدة:');
            recs.forEach(r => info(r.name + ':' + r.port));
            resolve(recs.map(r => r.name).filter(Boolean));
        });
    });
}

// ---------- 4) فحص DNS العادي ----------
function checkHost() {
    return new Promise((resolve) => {
        dns.lookup(host, (err, addr) => {
            if (err) {
                if (isSrv) {
                    // طبيعي: خادم SRV المجمّع قد لا يملك سجلاً من نوع A
                    info('ملاحظة: ' + host + ' لا يملك سجلاً مباشراً (A) — وهذا طبيعي مع mongodb+srv،');
                    info('         الاتصال يتم عبر الخوادم الحقيقية الظاهرة في سجلات SRV أعلاه.');
                } else {
                    bad('فشل ترجمة اسم الخادم: ' + err.code);
                    info('المشكلة في إعدادات DNS أو الشبكة');
                    failures++;
                }
            } else {
                ok('اسم الخادم يُترجم إلى: ' + addr);
            }
            resolve();
        });
    });
}

// ---------- 5) فحص المنفذ 27017 ----------
function checkPort(hostname) {
    return new Promise((resolve) => {
        const sock = net.createConnection({ host: hostname, port });
        const done = (msg, isErr) => {
            if (isErr) { failures++; bad(msg); } else ok(msg);
            try { sock.destroy(); } catch (e) {}
            resolve();
        };
        sock.setTimeout(10000);
        sock.on('connect', () => done('المنفذ ' + port + ' مفتوح — الاتصال بالشبكة سليم'));
        sock.on('timeout', () => done('انتهت المهلة على المنفذ ' + port + ' — جدار ناري أو IP غير مسموح في Atlas', true));
        sock.on('error', (e) => {
            if (e.code === 'ENOTFOUND' || e.code === 'EAI_AGAIN') {
                bad('فشل ترجمة اسم الخادم أثناء الاتصال (' + e.code + ')');
                info('هذه غالباً مشكلة DNS — راجع الحلول في الأعلى');
            } else {
                done('فشل الاتصال بالمنفذ ' + port + ': ' + e.code, true);
            }
            resolve();
        });
    });
}

(async () => {
    const srvHosts = await checkSrv();
    await checkHost();
    // إن فشل ترجمة اسم الخادم المجمّع، نجرّب أول خادم حقيقي من سجلات SRV
    const target = (srvHosts && srvHosts[0]) ? srvHosts[0] : host;
    if (target !== host) info('سنجرّب الاتصال بالخادم الحقيقي: ' + target);
    await checkPort(target);

    console.log('\n------------------------------------------');
    if (failures === 0) {
        console.log('🎉 كل الفحوصات ناجحة — إن استمر البوت في إظهار فشل الاتصال:');
        console.log('   • تأكد أن كلمة المرور في الرابط صحيحة (بدون رموز خاصة غير مُرمزة)');
        console.log('   • تأكد أن IP جهازك مسموح: Atlas ← Network Access');
        console.log('   • تأكد أن الكلاستر غير موقوف: Atlas ← Clusters');
    } else {
        console.log('⚠️ عدد المشاكل: ' + failures + ' — اتبع الحلول المذكورة أعلاه ثم أعد الفحص.');
    }
    console.log('------------------------------------------');
})();
