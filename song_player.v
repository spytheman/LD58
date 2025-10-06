import gg
import sokol.audio
import encoding.vorbis

struct SongPlayer {
mut:
	inited             bool
	song_path          string
	channels           int
	sample_rate        int
	pos                int
	paused             bool // pause decoding
	mute               bool
	finished           bool
	push_slack_ms      int = 5
	stream_rate        u32
	stream_channels    int
	stream_len_samples u32
	stream_len_seconds f32
	xerror             vorbis.VorbisErrorCode
	allocator          C.stb_vorbis_alloc = C.stb_vorbis_alloc{
		alloc_buffer:                 0
		alloc_buffer_length_in_bytes: 0
	}
	decoder            &C.stb_vorbis // TODO: cgen error with -cstrict -gcc, when this is = unsafe { nil } here
	framebuffer        &f32 = unsafe { nil }
	framebuffer_len    int  = 4 * 16384
}

pub fn new_song_player() &SongPlayer {
	mut p := &SongPlayer{
		decoder: unsafe { nil }
	}
	$if !wasm32_emscripten {
		p.init()
	}
	return p
}

fn (mut p SongPlayer) mute() {
	p.mute = !p.mute
}

fn (mut p SongPlayer) pause(state bool) {
	p.paused = state
}

fn (mut p SongPlayer) on_event(e &gg.Event) {
	if p.inited {
		return
	}
	if e.typ != .mouse_down {
		return
	}
	p.init()
	if p.song_path != '' {
		p.play_ogg_file(p.song_path) or {}
	}
}

fn (mut p SongPlayer) init() {
	p.inited = true
	audio.setup(buffer_frames: 512)
	p.framebuffer = unsafe { &f32(malloc(p.framebuffer_len)) }
	p.sample_rate = audio.sample_rate()
	p.channels = audio.channels()
	alloc_size := 200 * 1024
	p.allocator = C.stb_vorbis_alloc{
		alloc_buffer:                 unsafe { &char(vcalloc(alloc_size)) }
		alloc_buffer_length_in_bytes: alloc_size
	}
}

fn (mut p SongPlayer) stop() {
	p.free()
	audio.shutdown()
}

fn (mut p SongPlayer) free() {
	p.finished = false
	p.pos = 0
	p.close_decoder()
	unsafe {
		free(p.allocator.alloc_buffer)
		p.allocator.alloc_buffer = nil
	}
}

fn (mut p SongPlayer) close_decoder() {
	if !isnil(p.decoder) {
		C.stb_vorbis_close(p.decoder)
	}
}

fn (mut p SongPlayer) play_ogg_file(fpath string) ! {
	p.song_path = fpath
	if !p.inited {
		return
	}
	p.close_decoder()
	p.pos = 0
	p.xerror = .no_error
	p.decoder = C.stb_vorbis_open_filename(&char(fpath.str), voidptr(&p.xerror), &p.allocator)
	if isnil(p.decoder) || p.xerror != .no_error {
		return error('could not open ogg file: ${fpath}, xerror: ${p.xerror}')
	}
	info := C.stb_vorbis_get_info(p.decoder)
	p.stream_rate = info.sample_rate
	p.stream_channels = info.channels
	p.stream_len_samples = C.stb_vorbis_stream_length_in_samples(p.decoder)
	p.stream_len_seconds = C.stb_vorbis_stream_length_in_seconds(p.decoder)
	p.finished = false
	if !(p.channels == p.stream_channels && p.sample_rate == p.stream_rate) {
		audio.shutdown()
		audio.setup(
			buffer_frames: 512
			num_channels:  p.stream_channels
			sample_rate:   int(p.stream_rate)
		)
		p.sample_rate = audio.sample_rate()
		p.channels = audio.channels()
	}
	// println('> play_ogg_file: rate: ${p.sample_rate:5}, channels: ${p.channels:1} | stream rate: ${p.stream_rate:5}, channels: ${p.stream_channels:1}, samples: ${p.stream_len_samples:8} | seconds: ${p.stream_len_seconds:7.3f} | ${fpath}')
}

fn (mut p SongPlayer) restart() {
	if p.decoder == unsafe { nil } {
		return
	}
	C.stb_vorbis_seek_start(p.decoder)
	p.finished = false
}

fn (mut p SongPlayer) work() ! {
	if p.finished || p.paused || !p.inited {
		return
	}
	expected_frames := audio.expect()
	if expected_frames > 0 {
		mut decoded_frames := 0
		for decoded_frames < expected_frames {
			samples := C.stb_vorbis_get_samples_float_interleaved(p.decoder, p.channels,
				p.framebuffer, 512)
			if samples == 0 {
				p.finished = true
				break
			}
			if p.mute {
				unsafe { vmemset(p.framebuffer, 0, p.framebuffer_len) }
			}
			written_frames := audio.push(p.framebuffer, samples)
			decoded_frames += written_frames
			p.pos += samples
		}
	}
	if p.finished {
		p.restart()
	}
}
