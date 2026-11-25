extends GutTest

const MINI := "res://test/fixtures/stories/mini"
const T := [{"w": "Pipa", "t0": 0.2, "t1": 0.5}, {"w": "vuela.", "t0": 0.6, "t1": 0.9}]


func after_each() -> void:
	Audio.resume_all()
	Audio.stop_all()


func test_index_at() -> void:
	var k := KaraokeTimeline.new(T)
	assert_eq(k.index_at(0.1), -1)
	assert_eq(k.index_at(0.3), 0)
	assert_eq(k.index_at(0.55), 0, "entre palabras queda la anterior")
	assert_eq(k.index_at(0.7), 1)
	assert_eq(k.index_at(5.0), 1)
	assert_almost_eq(k.end_time(), 0.9, 0.001)


func test_estimate_when_no_timings() -> void:
	var k := KaraokeTimeline.estimated("Pipa vuela alto")
	assert_eq(k.size(), 3)
	assert_true(k.end_time() > 0.5)


func _narrator() -> Narrator:
	var n := Narrator.new()
	add_child_autofree(n)
	n.set_process(false)
	return n


func test_narrator_emits_words_and_finishes() -> void:
	var n := _narrator()
	watch_signals(n)
	n.narrate("Pipa está en la plaza.", MINI + "/vo/p1_simple.ogg", MINI + "/vo/p1_simple.json")
	assert_true(n.is_running())
	n.advance(0.25)
	assert_signal_emitted_with_parameters(n, "word", [0])
	for i in 40:
		n.advance(0.1)
	assert_signal_emitted(n, "finished")
	assert_false(n.is_running())
	assert_eq(get_signal_parameters(n, "word")[0], 4, "última palabra resaltada")


func test_narrator_frozen_while_paused() -> void:
	var n := _narrator()
	watch_signals(n)
	n.narrate("Pipa está en la plaza.", MINI + "/vo/p1_simple.ogg", MINI + "/vo/p1_simple.json")
	n.advance(0.25)
	Audio.pause_all()
	var before := n.clock
	n.advance(10.0)
	assert_eq(n.clock, before, "en segundo plano no avanza")
	assert_signal_not_emitted(n, "finished")
	Audio.resume_all()
	n.advance(0.1)
	assert_true(n.clock > before)


func test_speed_runs_clock_faster() -> void:
	Audio.set_speed(1.2)
	var n := _narrator()
	n.narrate("Pipa está en la plaza.", MINI + "/vo/p1_simple.ogg", MINI + "/vo/p1_simple.json")
	n.advance(1.0)
	assert_almost_eq(n.clock, 1.2, 0.001)
	Audio.set_speed(1.0)


func test_stop_does_not_emit_finished() -> void:
	var n := _narrator()
	watch_signals(n)
	n.narrate("Pipa", MINI + "/vo/p1_simple.ogg", MINI + "/vo/p1_simple.json")
	n.stop()
	assert_false(n.is_running())
	assert_signal_not_emitted(n, "finished")
