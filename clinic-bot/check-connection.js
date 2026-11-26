// أداة فحص سريعة: هل يستطيع جهازك الوصول إلى قاعدة بيانات MongoDB Atlas؟
// التشغيل: node check-connection.js
try { require('dotenv').config(); } catch (e) {}

const dns = require('dns').promises;
const net = require('net');

const uri = process.env.MONGODB_URI || '';
if (!uri) {
  console.log('❌ متغير MONGODB_URI غير موجود في ملف .env — انسخ .env.example إلى .env واملأ القيم.');
  process.exit(1);
}

let host = '';
try {
  const m = uri.match(/mongodb(?:\+srv)?:\/\/(?:[^@]+@)?([^/?]+)/);
  host = m ? m[1].split(',')[0] : '';
} catch (e) {}
if (!host) {
  console.log('❌ تعذّر قراءة اسم الخادم من MONGODB_URI — تحقق من الرابط في .env (لا مسافات، لا أسطر زائدة).');
  process.exit(1);
}

console.log('🔍 الخادم المطلوب:', host);
console.log('🔍 المنفذ المتوقع: 27017\n');

(async () => {
  // 1) فحص DNS (سجل SRV)
  try {
    const recs = await dns.resolveSrv(`_mongodb._tcp.${host}`);
    console.log('✅ DNS يعمل — تم العثور على خوادم القاعدة:', recs.map(r => `${r.name}:${r.port}`).join('، '));
  } catch (e) {
    console.log('❌ DNS فشل:', e.message);
    console.log('   → جرّب: غيّر DNS إلى 8.8.8.8 أو أعد تشغيل الراوتر، أو جرّب إنترنت آخر (هوت سبوت الجوال).');
  }

  // 2) فحص المنفذ TCP
  const sock = net.createConnection({ host, port: 27017, timeout: 8000 });
  sock.on('connect', () => {
    console.log('✅ المنفذ 27017 مفتوح — الاتصال بالشبكة سليم.');
    console.log('\n📌 إن ظهرت لك هذه الرسالة لكن البوت يقول "فشل الاتصال بـ MongoDB":');
    console.log('   فالمشكلة من قائمة IP في Atlas — افتح cloud.mongodb.com ← Network Access ← Add IP Address ← Allow Access From Anywhere،');
    console.log('   انتظر دقيقتين ثم أعد تشغيل البوت.');
    sock.end();
  });
  sock.on('timeout', () => {
    console.log('❌ انتهت المهلة — لا يصل جهازك إلى الخادم.');
    console.log('   الأسباب الشائعة: IP غير مسموح في Atlas (Network Access)، أو جدار ناري/مضاد فيروسات يحجب المنفذ 27017.');
    console.log('   جرّب: 1) إضافة IP في Atlas كما أعلاه  2) الاتصال عبر هوت سبوت الجوال لاختبار الشبكة.');
    sock.destroy();
  });
  sock.on('error', (e) => {
    console.log('❌ فشل الاتصال بالمنفذ:', e.message);
    console.log('   الأسباب الشائعة: IP غير مسموح في Atlas (Network Access)، أو جدار ناري يحجب المنفذ 27017.');
    console.log('   جرّب: 1) إضافة IP في Atlas  2) الاتصال عبر هوت سبوت الجوال لاختبار الشبكة.');
  });
})();
