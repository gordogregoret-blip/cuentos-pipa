extends Node
## Autoload "Audio": buses Master > Voz, Efectos, Musica.
## - Mientras suena un efecto, el bus Voz baja 8 dB (y vuelve al terminar).
## - La velocidad del relato cambia pitch_scale del reproductor de voz y un
##   AudioEffectPitchShift en el bus Voz lo compensa, así la voz no se vuelve aguda.
## - En segundo plano pausa todo y al volver retoma donde estaba.

signal voice_finished
signal paused_changed(is_paused: bool)

const DUCK_DB := -8.0
const SFX_VOICES := 4

var paused: bool = false
var speed: float = 1.0

var _voice: AudioStreamPlayer
var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _ducking: int = 0
var _voice_linear: float = 1.0
var _pitch: AudioEffectPitchShift


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_voice = _player(&"Voz")
	_voice.finished.connect(func() -> void: voice_finished.emit())
	_music = _player(&"Musica")
	for i in SFX_VOICES:
		var p := _player(&"Efectos")
		p.finished.connect(_on_sfx_done.bind(p))
		_sfx.append(p)
	_pitch = AudioEffectPitchShift.new()
	var voz := AudioServer.get_bus_index(&"Voz")
	AudioServer.add_bus_effect(voz, _pitch)
	AudioServer.set_bus_effect_enabled(voz, AudioServer.get_bus_effect_count(voz) - 1, false)
	if has_node("/root/Store"):
		apply_settings()


func apply_settings() -> void:
	var store := get_node("/root/Store")
	set_bus_volume(&"Voz", store.setting("vol_voz"))
	set_bus_volume(&"Efectos", store.setting("vol_efectos"))
	set_bus_volume(&"Musica", store.setting("vol_musica"))
	set_speed(store.setting("speed"))


func voice_player() -> AudioStreamPlayer:
	return _voice


func pitch_effect() -> AudioEffectPitchShift:
	return _pitch


func set_bus_volume(bus: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if bus == &"Voz":
		_voice_linear = linear
	AudioServer.set_bus_mute(idx, linear <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)) + (DUCK_DB if bus == &"Voz" and _ducking > 0 else 0.0))


func set_speed(s: float) -> void:
	speed = clampf(s, 0.5, 2.0)
	_voice.pitch_scale = speed
	_pitch.pitch_scale = 1.0 / speed
	var voz := AudioServer.get_bus_index(&"Voz")
	for i in AudioServer.get_bus_effect_count(voz):
		if AudioServer.get_bus_effect(voz, i) == _pitch:
			AudioServer.set_bus_effect_enabled(voz, i, not is_equal_approx(speed, 1.0))


## Devuelve false si el archivo no existe (y avisa voice_finished enseguida).
func play_voice(path: String) -> bool:
	_voice.stop()
	var stream := _load(path)
	if stream == null:
		voice_finished.emit.call_deferred()
		return false
	_voice.stream = stream
	_voice.play()
	_voice.stream_paused = paused
	return true


func stop_voice() -> void:
	_voice.stop()


func is_voice_playing() -> bool:
	return _voice.playing


func play_sfx(path: String) -> void:
	var stream := _load(path)
	if stream == null:
		return
	var p := _free_sfx_player()
	if p.playing:
		_on_sfx_done(p)
	p.stream = stream
	p.play()
	_ducking += 1
	set_bus_volume(&"Voz", _voice_linear)


func play_music(path: String) -> void:
	var stream := _load(path)
	if stream == null or (_music.playing and _music.stream == stream):
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	_music.stream = stream
	_music.play()


func stop_all() -> void:
	_voice.stop()
	for p in _sfx:
		p.stop()
	_ducking = 0
	set_bus_volume(&"Voz", _voice_linear)


func pause_all() -> void:
	_set_paused(true)


func resume_all() -> void:
	_set_paused(false)


func _set_paused(on: bool) -> void:
	if paused == on:
		return
	paused = on
	for p in [_voice, _music] + _sfx:
		p.stream_paused = on
	paused_changed.emit(on)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			pause_all()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			resume_all()


func _on_sfx_done(_p: AudioStreamPlayer) -> void:
	_ducking = maxi(0, _ducking - 1)
	set_bus_volume(&"Voz", _voice_linear)


func _free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx:
		if not p.playing:
			return p
	return _sfx[0]


func _player(bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus
	add_child(p)
	return p


func _load(path: String) -> AudioStream:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream
