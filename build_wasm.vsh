import log

log.info('cleanup ...')
system('rm -rf ld58_gc.*')
log.info('compiling ...')
system('v -prod -os wasm32_emscripten -o ld58_gc.js .')
system('ls -la index.html ld58_gc*')
// println('to release,      run:  rsync -av ld58_gc.* index.html zeus:/websites/url4e.com/tmp/ld58/')
// println('then to check, visit:  https://url4e.com/tmp/ld58/index.html')
log.info('rsyncing ...')
system('rsync -av ld58_gc.* index.html zeus:/websites/url4e.com/tmp/ld58/')
log.warn('Visit https://url4e.com/tmp/ld58/index.html to check the released version.')
