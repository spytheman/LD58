.PHONY: wasm32

wasm:
	rm -rf ld58_gc.*; v -os wasm32_emscripten -o ld58_gc.js .
