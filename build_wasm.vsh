system('rm -rf ld58_gc.*')
system('v -keepc -cg -os wasm32_emscripten -o ld58_gc.js .')
system('ls -la index.html ld58_gc*')
