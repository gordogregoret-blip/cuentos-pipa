extends GutTest


func test_release_before_three_seconds_does_not_pass() -> void:
	var g := ParentGateLogic.new()
	g.press()
	g.tick(2.9)
	g.release()
	assert_eq(g.state, &"hold")
	assert_eq(g.progress(), 0.0, "soltar reinicia")


func test_three_seconds_opens_the_question() -> void:
	var g := ParentGateLogic.new()
	g.press()
	g.tick(1.5)
	g.tick(1.5)
	assert_eq(g.state, &"order")
	assert_eq(g.numbers.size(), 3)
	var sorted := g.numbers.duplicate()
	sorted.sort()
	assert_eq(sorted, [1, 2, 3])


func test_ticks_without_press_do_nothing() -> void:
	var g := ParentGateLogic.new()
	g.tick(5.0)
	assert_eq(g.state, &"hold")


func test_right_order_opens() -> void:
	var g := ParentGateLogic.new()
	g.press()
	g.tick(3.0)
	assert_false(g.tap(1))
	assert_false(g.tap(2))
	assert_true(g.tap(3))
	assert_eq(g.state, &"open")


func test_wrong_order_restarts_quietly() -> void:
	var g := ParentGateLogic.new()
	g.press()
	g.tick(3.0)
	g.tap(1)
	g.tap(3)
	assert_eq(g.state, &"order", "sigue en la consigna, sin mensaje de error")
	assert_eq(g.expected(), 1)
	g.tap(1)
	g.tap(2)
	assert_true(g.tap(3))


func test_gate_overlay_emits_passed() -> void:
	var gate := ParentGate.new()
	add_child_autofree(gate)
	watch_signals(gate)
	gate.logic.press()
	gate.logic.tick(3.0)
	gate.sync()
	assert_eq(gate.number_buttons.size(), 3)
	for n in [1, 2, 3]:
		for b in gate.number_buttons:
			if b.text == str(n):
				b.pressed.emit()
	assert_signal_emitted(gate, "passed")


func test_numbers_are_written_digits() -> void:
	var gate := ParentGate.new()
	add_child_autofree(gate)
	gate.logic.press()
	gate.logic.tick(3.0)
	gate.sync()
	for b in gate.number_buttons:
		assert_true(b.text in ["1", "2", "3"])
		assert_null(b.icon, "números escritos, no dibujos")
