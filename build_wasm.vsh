system('rm -rf ld58_gc.*')
system('v -os wasm32_emscripten -o ld58_gc.js .')
system('ls -la index.html ld58_gc*')
