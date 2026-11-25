class_name Narrator
extends Node
## Lee una página: hace sonar la voz y avisa qué palabra se está diciendo.
## Lleva su propio reloj (delta × velocidad) para que el karaoke sea exacto,
## se congele en segundo plano y se pueda probar sin audio real.

signal started
signal word(index: int)
signal finished

const TAIL := 0.35

var clock: float = 0.0
var timeline: KaraokeTimeline
var duration: float = 0.0

var _running: bool = false
var _last: int = -1


func _process(delta: float) -> void:
	advance(delta)


func narrate(text: String, vo_path: String, timings_path: String) -> void:
	timeline = KaraokeTimeline.from_file(timings_path, text)
	clock = 0.0
	_last = -1
	duration = timeline.end_time() + TAIL
	if Audio.play_voice(vo_path):
		var length := Audio.voice_player().stream.get_length()
		if length > 0.0:
			duration = maxf(duration, length)
	_running = true
	started.emit()


func advance(delta: float) -> void:
	if not _running or Audio.paused:
		return
	clock += delta * Audio.speed
	var idx := timeline.index_at(clock)
	if idx != _last and idx >= 0:
		_last = idx
		word.emit(idx)
	if clock >= duration:
		_running = false
		finished.emit()


func stop() -> void:
	_running = false
	Audio.stop_voice()


func is_running() -> bool:
	return _running


func current_word() -> int:
	return _last
