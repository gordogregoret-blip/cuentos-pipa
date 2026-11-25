extends GutTest


func test_notch_on_left_and_symmetric_margin() -> void:
	var m := SafeArea.margins(Rect2i(80, 0, 1840, 1080), Vector2i(2000, 1080))
	assert_eq(m, {"left": 80, "top": 0, "right": 80, "bottom": 0})


func test_full_screen_no_margins() -> void:
	assert_eq(SafeArea.margins(Rect2i(0, 0, 1920, 1080), Vector2i(1920, 1080)), {"left": 0, "top": 0, "right": 0, "bottom": 0})


func test_empty_safe_rect_means_no_margins() -> void:
	assert_eq(SafeArea.margins(Rect2i(), Vector2i(1920, 1080)), {"left": 0, "top": 0, "right": 0, "bottom": 0})


func test_scaled_to_canvas() -> void:
	# Pantalla física 2x la base: los márgenes se dividen por la escala.
	var m := SafeArea.to_canvas({"left": 80, "top": 0, "right": 40, "bottom": 20}, 2.0)
	assert_eq(m, {"left": 40.0, "top": 0.0, "right": 20.0, "bottom": 10.0})
