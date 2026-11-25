extends GutTest


func test_base_resolution_is_1920x1080() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1920)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1080)


func test_stretch_canvas_items_expand() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_sensor_landscape() -> void:
	# DisplayServer.SCREEN_SENSOR_LANDSCAPE == 4 in project settings enum order
	assert_eq(ProjectSettings.get_setting("display/window/handheld/orientation"), DisplayServer.SCREEN_SENSOR_LANDSCAPE)


func test_compatibility_renderer() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"), "gl_compatibility")


func test_main_scene_set() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_true(ResourceLoader.exists(main), "main scene exists: %s" % main)
