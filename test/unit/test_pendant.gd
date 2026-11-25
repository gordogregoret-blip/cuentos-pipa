extends GutTest


func test_six_colors_and_emotions() -> void:
	assert_eq(Pendant.EMOTION, {"amarillo": "contenta", "azul": "triste", "rojo": "enojada",
		"violeta": "sorprendida", "verde": "tranquila", "naranja": "con miedo"})
	assert_eq(Pendant.COLORS.keys(), Pendant.EMOTION.keys())


func test_phrase_is_literal() -> void:
	assert_eq(Pendant.phrase("azul"), "El colgante está azul. Pipa está triste.")
	assert_eq(Pendant.phrase("naranja"), "El colgante está naranja. Pipa tiene miedo.")


func test_rig_state_for_color() -> void:
	assert_eq(Pendant.rig_state("amarillo"), &"contento")
	assert_eq(Pendant.rig_state("azul"), &"triste")
	assert_eq(Pendant.rig_state("violeta"), &"sorpresa")


func test_view_changes_color() -> void:
	var v := PendantView.new()
	add_child_autofree(v)
	v.set_color("verde", false)
	assert_eq(v.color_name, "verde")
	assert_eq(v.gem.modulate, Pendant.COLORS["verde"])


func test_view_fades_softly() -> void:
	var v := PendantView.new()
	add_child_autofree(v)
	v.set_color("amarillo", false)
	v.set_color("azul")
	assert_ne(v.gem.modulate, Pendant.COLORS["azul"], "no cambia de golpe")
	await wait_seconds(Pendant.FADE + 0.1)
	assert_eq(v.gem.modulate, Pendant.COLORS["azul"])


func test_due_changes_by_fraction() -> void:
	var entries := [{"color": "naranja", "at": 0.2}, {"color": "verde", "at": 0.7}]
	assert_eq(Pendant.due(entries, 0.1), "")
	assert_eq(Pendant.due(entries, 0.3), "naranja")
	assert_eq(Pendant.due(entries, 0.9), "verde")


func test_pendant_lives_on_pipa_without_z_index() -> void:
	var data := StoryData.load_from("res://test/fixtures/stories/mini")
	var pv := PageView.new()
	pv.build(data, "p1")
	add_child_autofree(pv)
	assert_not_null(pv.pendant)
	assert_eq(pv.pendant.get_parent(), pv.pipa, "colgado de Pipa")
	assert_eq(pv.pendant.z_index, 0, "no se dibuja encima de las capas")
	assert_eq(pv.pendant.get_index(), pv.pipa.get_child_count() - 1, "encima del cuerpo de Pipa")
