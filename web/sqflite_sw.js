// SQLite Service Worker for sqflite_common_ffi_web
// This loads the sqlite3.wasm and sqlite3.js for web operations

console.log('[sqflite_sw.js] Loading sqlite3.wasm.js...');

// Import the sqlite3 JavaScript module
importScripts('sqlite3.wasm.js');

console.log('[sqflite_sw.js] Service worker initialized');

// Handle initialization messages
self.addEventListener('message', (event) => {
  if (event.data.type === 'init') {
    console.log('[sqflite_sw.js] Init message received');
    try {
      event.ports[0].postMessage({ success: true });
    } catch (e) {
      console.error('[sqflite_sw.js] Init error:', e);
      event.ports[0].postMessage({ error: String(e) });
    }
  }
});
