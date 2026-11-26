// تشغيل دائم عبر pm2 — الأسرار تُقرأ من ملف .env (لا تُكتب هنا أبداً)
require('dotenv').config({ path: require('path').join(__dirname, '.env') });

module.exports = {
  apps: [
    {
      name: 'clinic-bot',
      script: 'index.js',
      cwd: __dirname,
      autorestart: true,
      restart_delay: 10000,
      max_restarts: 50,
      max_memory_restart: '1500M',
      time: true,
      env: {
        PORT: process.env.PORT || 7861,
        MONGODB_URI: process.env.MONGODB_URI,
        GEMINI_API_KEY: process.env.GEMINI_API_KEY,
        RESET_WA_SESSION: process.env.RESET_WA_SESSION || '0',
        WA_PAIR_PHONE: process.env.WA_PAIR_PHONE || '',
      },
    },
  ],
};
