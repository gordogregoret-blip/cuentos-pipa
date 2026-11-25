extends GutTest

const SFX := "res://test/fixtures/stories/mini/sfx/pop.ogg"


func after_each() -> void:
	Audio.stop_all()
	Audio.resume_all()
	Audio.set_speed(1.0)
	Audio.set_bus_volume(&"Voz", 1.0)


func _db(bus: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


func test_buses() -> void:
	var names: Array[String] = []
	for i in AudioServer.bus_count:
		names.append(AudioServer.get_bus_name(i))
	assert_eq(names, ["Master", "Voz", "Efectos", "Musica"] as Array[String])
	for b in [&"Voz", &"Efectos", &"Musica"]:
		assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(b)), &"Master")


func test_bus_volume_linear() -> void:
	Audio.set_bus_volume(&"Efectos", 0.5)
	assert_almost_eq(_db(&"Efectos"), linear_to_db(0.5), 0.01)
	Audio.set_bus_volume(&"Efectos", 0.0)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"Efectos")))
	Audio.set_bus_volume(&"Efectos", 1.0)


func test_sfx_ducks_voice_8_db_and_restores() -> void:
	Audio.set_bus_volume(&"Voz", 1.0)
	Audio.play_sfx(SFX)
	assert_almost_eq(_db(&"Voz"), -8.0, 0.01)
	Audio._on_sfx_done(null)
	assert_almost_eq(_db(&"Voz"), 0.0, 0.01)


func test_missing_sfx_does_not_duck() -> void:
	Audio.play_sfx("res://no/existe.ogg")
	assert_almost_eq(_db(&"Voz"), 0.0, 0.01)


func test_speed_shifts_pitch_back() -> void:
	Audio.set_speed(1.2)
	assert_almost_eq(Audio.voice_player().pitch_scale, 1.2, 0.001)
	var fx := Audio.pitch_effect()
	assert_not_null(fx)
	assert_almost_eq(fx.pitch_scale, 1.0 / 1.2, 0.001)
	Audio.set_speed(1.0)
	assert_almost_eq(Audio.voice_player().pitch_scale, 1.0, 0.001)


func test_pause_and_resume() -> void:
	Audio.play_voice("res://test/fixtures/stories/mini/vo/p1_simple.ogg")
	Audio.pause_all()
	assert_true(Audio.paused)
	assert_true(Audio.voice_player().stream_paused)
	Audio.resume_all()
	assert_false(Audio.paused)


func test_background_notification_pauses() -> void:
	Audio._notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_true(Audio.paused)
	Audio._notification(NOTIFICATION_APPLICATION_RESUMED)
	assert_false(Audio.paused)
