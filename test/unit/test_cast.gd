extends GutTest
## El elenco viene de Nido: piezas SVG + CharacterRig. Los nombres del cuento
## (Pipa, Sofi, Bubu, Fido, Tati) se mapean a los ids de arte de Nido.

const REQUIRED_PARTS := ["cuerpo", "cabeza", "ojo_izq", "ojo_der", "boca", "brazo_izq", "brazo_der"]


func after_each() -> void:
	Motion.reduced = false


func _rig(id: String) -> CharacterRig:
	var rig := CharacterRig.new()
	rig.character_id = id
	add_child_autofree(rig)
	return rig


func _tex_name(sprite: Sprite2D) -> String:
	return sprite.texture.resource_path.get_file()


func test_cast_ids_map_story_names_to_art() -> void:
	assert_eq(CharacterDefs.CAST_IDS, {"pipa": "pipa", "sofi": "coneja", "bubu": "oso", "fido": "perro", "tati": "gato"})


func test_every_texture_lives_in_art_cast() -> void:
	for id in CharacterDefs.CAST_IDS:
		for tex_path in CharacterDefs.all_textures(id):
			assert_true(tex_path.begins_with("res://art/cast/"), tex_path)
			assert_true(ResourceLoader.exists(tex_path), tex_path)


func test_builds_all_parts_for_each_character() -> void:
	for id in CharacterDefs.CAST_IDS:
		var rig := _rig(id)
		for part in REQUIRED_PARTS:
			assert_not_null(rig.get_part(part), "%s sin %s" % [id, part])


func test_offsets_match_svg_viewbox() -> void:
	var re := RegEx.create_from_string('viewBox="(-?[\\d.]+) (-?[\\d.]+) ')
	for id in CharacterDefs.CAST_IDS:
		for tex_path in CharacterDefs.all_textures(id):
			var m := re.search(FileAccess.get_file_as_string(tex_path))
			assert_not_null(m, tex_path)
			assert_eq(CharacterDefs.offset_for(tex_path), Vector2(float(m.get_string(1)), float(m.get_string(2))), tex_path)


func test_contento_swaps_face() -> void:
	var rig := _rig("sofi")
	rig.set_state(&"contento")
	assert_eq(_tex_name(rig.get_part("ojo_izq")), "ojo_feliz.svg")
	assert_eq(_tex_name(rig.get_part("boca")), "boca_feliz.svg")


func test_triste_shows_brows() -> void:
	var rig := _rig("bubu")
	rig.set_state(&"triste")
	assert_eq(_tex_name(rig.get_part("boca")), "boca_triste.svg")
	assert_true(rig.get_part("ceja_izq").visible)


func test_pipa_talk_opens_beak() -> void:
	var rig := _rig("pipa")
	rig.set_state(&"contento")
	assert_eq(_tex_name(rig.get_part("boca")), "pipa_pico_abierto.svg")


func test_reduced_motion_stops_breathing() -> void:
	Motion.reduced = true
	assert_false(_rig("fido").is_breathing())
	Motion.reduced = false
	assert_true(_rig("fido").is_breathing())
