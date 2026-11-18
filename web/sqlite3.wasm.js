// SQLite3 WASM Loader
// This loads the sqlite3.wasm file

console.log('[sqlite3.wasm.js] Initializing SQLite3 WASM...');

// This will be loaded by the service worker
var sqlite3InitModule = function () {
    return {
        locateFile: function (file) {
            if (file === 'sqlite3.wasm') {
                return 'sqlite3.wasm';
            }
            return file;
        }
    };
};

console.log('[sqlite3.wasm.js] SQLite3 WASM initialized');
