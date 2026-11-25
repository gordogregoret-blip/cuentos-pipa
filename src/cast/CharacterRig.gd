class_name CharacterRig
extends Node2D
## Copiado de Nido (src/pueblo/kit/CharacterRig.gd) y adaptado a Cuentos.
## A cutout character (Pipa or a customer) assembled from CharacterDefs.
## The node's origin is the character's base, centred: place it where the
## feet would stand. Life comes from small, constant motion — breathing,
## blinking, a mouth that moves while it speaks — and every state change
## swaps face parts on the spot so a reaction lands in the same frame as
## the tap that caused it.

signal state_changed(state: StringName)

const STATES: Array[StringName] = [&"idle", &"hablar", &"contento", &"triste", &"saludar", &"comer", &"esperar", &"caminar", &"sorpresa", &"pensar", &"bailar"]
## Each character's own little thing it does now and then while idle.
const QUIRKS: Array[String] = ["aletear", "orejas", "bostezo", "saltito", "curioso"]
const QUIRK_MIN_S := 6.0
const QUIRK_MAX_S := 12.0
const SHADOW_COLOR := Color(0.29, 0.18, 0.13, 0.16)
const STEP_SECONDS := 0.2
const SURPRISE_EYES := 1.28
const BREATH_SECONDS := 2.2
const BREATH_SCALE := 1.02
const TALK_FLAP_SECONDS := 0.12
const EYE_LOOK_PX := 6.0

@export var character_id: String = "pipa"

var state: StringName = &"idle"

var _def: Dictionary
var _root: Node2D  # everything hangs from here, so breathing/hops never move the node itself
var _parts: Dictionary = {}
var _rest_rot: Dictionary = {}
var _eye_home: Dictionary = {}
var _breath: Tween
var _pose: Tween
var _talk_until_ms: int = 0
var _talk_timer: Timer
var _blink_timer: Timer
var _quirk_timer: Timer
var _gesture: Tween
var _loop: Tween  # walking steps or dancing; one at a time
var _loop_kind: StringName = &""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_def = CharacterDefs.get_def(character_id)
	_add_shadow()
	_root = Node2D.new()
	_root.name = "Rig"
	add_child(_root)
	for part in _def.get("parts", []):
		_build_part(part)
	_talk_timer = Timer.new()
	_talk_timer.wait_time = TALK_FLAP_SECONDS
	_talk_timer.timeout.connect(_on_talk_flap)
	add_child(_talk_timer)
	_blink_timer = Timer.new()
	_blink_timer.one_shot = true
	_blink_timer.timeout.connect(_on_blink)
	add_child(_blink_timer)
	_blink_timer.start(_rng.randf_range(2.5, 5.0))
	_quirk_timer = Timer.new()
	_quirk_timer.one_shot = true
	_quirk_timer.timeout.connect(_on_quirk_timer)
	add_child(_quirk_timer)
	if Motion.enabled():
		_quirk_timer.start(_rng.randf_range(QUIRK_MIN_S, QUIRK_MAX_S))
	_apply_state(&"idle")
	_start_breathing()


func get_part(part_name: String) -> Node2D:
	return _parts.get(part_name)


func is_breathing() -> bool:
	return _breath != null and _breath.is_valid()


## For a screen that moves her on its own rhythm (the calm corner's 12 s
## breath): her quick idle breath would fight it.
func stop_breathing() -> void:
	if _breath and _breath.is_valid():
		_breath.kill()
	_breath = null
	if _root:
		_root.scale = Vector2.ONE


func set_state(new_state: StringName) -> void:
	if not new_state in STATES:
		return
	state = new_state
	_apply_state(new_state)
	state_changed.emit(new_state)


## Mouth flaps for `seconds`, then rests in the current state's mouth.
func talk_for(seconds: float) -> void:
	_talk_until_ms = Time.get_ticks_msec() + int(seconds * 1000.0)
	_set_mouth("talk")
	_talk_timer.start()
	_gesture_for(seconds)


func is_gesturing() -> bool:
	return _gesture != null and _gesture.is_valid() and _gesture.is_running()


func is_dancing() -> bool:
	return _loop_kind == &"bailar" and _loop != null and _loop.is_valid()


## Walks (bobbing steps) to x and goes back to idle. Without motion it
## jumps there; the returned tween still finishes so callers can await it.
func walk_to(x: float, seconds: float) -> Tween:
	set_state(&"caminar")
	var t := create_tween()
	t.tween_property(self, "position:x", x, Motion.duration(seconds)).set_trans(Tween.TRANS_SINE)
	t.tween_callback(set_state.bind(&"idle"))
	return t


## The character's own idle gesture (CharacterDefs "quirk"). False when it
## can't play now: motion off, busy in another state, or talking.
func play_quirk() -> bool:
	if not Motion.enabled() or state != &"idle" or is_talking():
		return false
	_kill_pose()
	_pose = create_tween()
	match String(_def.get("quirk", "")):
		"aletear":
			# Both wings out and back, twice (the right one is mirrored).
			var left: Node2D = _parts["brazo_izq"]
			var right: Node2D = _parts["brazo_der"]
			for i in 2:
				_pose.tween_property(left, "rotation", _rest_rot["brazo_izq"] + 0.6, 0.12)
				_pose.parallel().tween_property(right, "rotation", _rest_rot["brazo_der"] - 0.6, 0.12)
				_pose.tween_property(left, "rotation", _rest_rot["brazo_izq"], 0.12)
				_pose.parallel().tween_property(right, "rotation", _rest_rot["brazo_der"], 0.12)
		"orejas":
			for i in 3:
				for ear_name in ["oreja_izq", "oreja_der"]:
					var ear: Node2D = _parts.get(ear_name)
					if ear:
						var dir := -1.0 if ear_name == "oreja_izq" else 1.0
						_pose.parallel().tween_property(ear, "rotation", _rest_rot[ear_name] + 0.25 * dir, 0.1)
				for ear_name in ["oreja_izq", "oreja_der"]:
					if _parts.has(ear_name):
						_pose.chain().tween_property(_parts[ear_name], "rotation", _rest_rot[ear_name], 0.1)
		"bostezo":
			var head: Node2D = _parts["cabeza"]
			_set_eyes(CharacterDefs.S + "ojo_feliz.svg")
			_set_mouth("talk")
			_pose.tween_property(head, "rotation", -0.14, 0.5).set_trans(Tween.TRANS_SINE)
			_pose.parallel().tween_property(_parts["brazo_izq"], "rotation", _rest_rot["brazo_izq"] + 0.9, 0.5)
			_pose.parallel().tween_property(_parts["brazo_der"], "rotation", _rest_rot["brazo_der"] - 0.9, 0.5)
			_pose.tween_interval(0.7)
			_pose.tween_property(head, "rotation", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
			_pose.parallel().tween_property(_parts["brazo_izq"], "rotation", _rest_rot["brazo_izq"], 0.5)
			_pose.parallel().tween_property(_parts["brazo_der"], "rotation", _rest_rot["brazo_der"], 0.5)
			_pose.tween_callback(_apply_face.bind(&"idle"))
		"curioso":
			var h: Node2D = _parts["cabeza"]
			for tilt in [0.22, -0.22, 0.0]:
				_pose.tween_property(h, "rotation", tilt, 0.35).set_trans(Tween.TRANS_SINE)
				_pose.tween_interval(0.25)
		"saltito":
			for i in 2:
				_pose.tween_property(_root, "position:y", -22.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_pose.tween_property(_root, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			for ear_name in ["oreja_izq", "oreja_der"]:
				if _parts.has(ear_name):
					var e: Node2D = _parts[ear_name]
					_pose.parallel().tween_property(e, "rotation", _rest_rot[ear_name], 0.1)
		_:
			return false
	return true


func is_talking() -> bool:
	return Time.get_ticks_msec() < _talk_until_ms


## Eyes slide a few pixels toward a point (what the child is touching).
func look_at_point(global_point: Vector2) -> void:
	for eye_name in ["ojo_izq", "ojo_der"]:
		var eye: Sprite2D = _parts.get(eye_name)
		if eye == null:
			continue
		var home: Vector2 = _eye_home[eye_name]
		var holder := eye.get_parent() as Node2D
		var dir: Vector2 = (global_point - holder.to_global(home)).normalized()
		eye.position = home + dir * EYE_LOOK_PX


func look_ahead() -> void:
	for eye_name in _eye_home:
		_parts[eye_name].position = _eye_home[eye_name]


## Raises the waving arm toward a point (Pipa's "it's that one" hint).
func point_at(global_point: Vector2) -> void:
	var arm: Node2D = _parts.get("brazo_der")
	if arm == null:
		return
	# Arm art hangs along +y; aim that axis at the target.
	var to_target := global_point - arm.global_position
	var angle := to_target.angle() - PI / 2.0
	if arm.scale.x < 0.0:
		angle = -angle
	_kill_pose()
	_pose = create_tween()
	_pose.tween_property(arm, "rotation", angle, Motion.duration(0.2)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func rest_arms() -> void:
	_kill_pose()
	for arm_name in ["brazo_izq", "brazo_der"]:
		if _parts.has(arm_name):
			_parts[arm_name].rotation = _rest_rot[arm_name]


func _build_part(part: Dictionary) -> void:
	var node: Node2D
	var tex_path: String = part.get("tex", "")
	if tex_path == "":
		node = Node2D.new()
	else:
		var sprite := Sprite2D.new()
		sprite.texture = load(tex_path)
		sprite.centered = false
		sprite.offset = CharacterDefs.offset_for(tex_path)
		node = sprite
	node.name = part["name"]
	node.position = part.get("pos", Vector2.ZERO)
	node.rotation = part.get("rot", 0.0)
	if part.get("mirror", false):
		node.scale.x = -1.0
	node.visible = not part.get("hidden", false)
	var parent: Node = _parts.get(part.get("parent", ""), _root)
	parent.add_child(node)
	_parts[part["name"]] = node
	_rest_rot[part["name"]] = node.rotation
	if String(part["name"]).begins_with("ojo_"):
		_eye_home[part["name"]] = node.position


func _apply_state(s: StringName) -> void:
	_kill_pose()
	_stop_loop()
	rest_arms()
	_root.position = Vector2.ZERO
	_root.rotation = 0.0
	_apply_face(s)
	_show_brows(s == &"triste")
	var head: Node2D = _parts.get("cabeza")
	if head:
		head.rotation = 0.0
		match s:
			&"triste":
				head.rotation = 0.08
			&"pensar":
				head.rotation = -0.2
	match s:
		&"contento":
			_hop()
		&"saludar":
			_wave()
		&"comer":
			_chew()
		&"sorpresa":
			for eye_name in ["ojo_izq", "ojo_der"]:
				if _parts.has(eye_name):
					_parts[eye_name].scale = Vector2(SURPRISE_EYES, SURPRISE_EYES)
			_hop()
		&"pensar":
			var arm: Node2D = _parts.get("brazo_der")
			if arm:
				arm.rotation = _def.get("wave_up", -2.6) * 0.55
		&"caminar":
			_start_loop(&"caminar")
		&"bailar":
			_start_loop(&"bailar")


## Eyes and mouth for a state, in the same frame (no tween).
func _apply_face(s: StringName) -> void:
	var happy_eyes := s == &"contento" or s == &"bailar"
	_set_eyes(CharacterDefs.S + ("ojo_feliz.svg" if happy_eyes else "ojo_abierto.svg"))
	match s:
		&"contento", &"saludar", &"bailar":
			_set_mouth("happy")
		&"triste":
			_set_mouth("sad")
		&"sorpresa":
			_set_mouth("talk")
		_:
			_set_mouth("closed")


## Looping body motion: bobbing steps, or a happy sway with the arms up.
func _start_loop(kind: StringName) -> void:
	if not Motion.enabled():
		return
	_loop_kind = kind
	_loop = create_tween().set_loops()
	if kind == &"caminar":
		for side in [-1.0, 1.0]:
			_loop.tween_property(_root, "position:y", -16.0, STEP_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_loop.parallel().tween_property(_root, "rotation", 0.045 * side, STEP_SECONDS / 2.0)
			_loop.tween_property(_root, "position:y", 0.0, STEP_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		var left: Node2D = _parts.get("brazo_izq")
		var right: Node2D = _parts.get("brazo_der")
		var up: float = _def.get("wave_up", -2.6) * 0.7
		for side in [-1.0, 1.0]:
			_loop.tween_property(_root, "rotation", 0.09 * side, 0.32).set_trans(Tween.TRANS_SINE)
			if left and right:
				_loop.parallel().tween_property(left if side < 0 else right, "rotation",
					(-up if side < 0 else up), 0.32)
				_loop.parallel().tween_property(right if side < 0 else left, "rotation",
					_rest_rot["brazo_der" if side < 0 else "brazo_izq"], 0.32)


func _stop_loop() -> void:
	if _loop and _loop.is_valid():
		_loop.kill()
	_loop = null
	_loop_kind = &""


## Little nods and a hand gesture while speaking.
func _gesture_for(seconds: float) -> void:
	if not Motion.enabled() or state in [&"caminar", &"bailar", &"pensar"]:
		return
	if _gesture and _gesture.is_valid():
		_gesture.kill()
	var head: Node2D = _parts.get("cabeza")
	var arm: Node2D = _parts.get("brazo_izq")
	if head == null:
		return
	var base := head.rotation
	_gesture = create_tween()
	var nods := maxi(1, int(seconds / 0.45))
	for i in nods:
		_gesture.tween_property(head, "rotation", base + (0.05 if i % 2 == 0 else -0.04), 0.22).set_trans(Tween.TRANS_SINE)
		if arm and i == 0:
			_gesture.parallel().tween_property(arm, "rotation", _rest_rot["brazo_izq"] + 0.45, 0.22)
	_gesture.tween_property(head, "rotation", base, 0.2).set_trans(Tween.TRANS_SINE)
	if arm:
		_gesture.parallel().tween_property(arm, "rotation", _rest_rot["brazo_izq"], 0.2)


func _add_shadow() -> void:
	var size: Vector2 = _def.get("shadow", Vector2(300, 40))
	var shadow := Polygon2D.new()
	shadow.name = "Sombra"
	var pts := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		pts.append(Vector2(cos(a) * size.x / 2.0, sin(a) * size.y / 2.0 + 18.0))
	shadow.polygon = pts
	shadow.color = SHADOW_COLOR
	add_child(shadow)


func _on_quirk_timer() -> void:
	play_quirk()
	_quirk_timer.start(_rng.randf_range(QUIRK_MIN_S, QUIRK_MAX_S))


func _set_eyes(tex_path: String) -> void:
	for eye_name in ["ojo_izq", "ojo_der"]:
		var eye: Sprite2D = _parts.get(eye_name)
		if eye:
			eye.texture = load(tex_path)
			eye.offset = CharacterDefs.offset_for(tex_path)
			eye.scale = Vector2.ONE


func _set_mouth(kind: String) -> void:
	var mouth: Sprite2D = _parts.get("boca")
	var tex_path: String = _def.get("mouth", {}).get(kind, "")
	if mouth == null or tex_path == "":
		return
	mouth.texture = load(tex_path)
	mouth.offset = CharacterDefs.offset_for(tex_path)


func _resting_mouth() -> String:
	match state:
		&"contento", &"saludar", &"bailar":
			return "happy"
		&"triste":
			return "sad"
	return "closed"


func _show_brows(on: bool) -> void:
	for brow_name in ["ceja_izq", "ceja_der"]:
		var brow: Node2D = _parts.get(brow_name)
		if brow:
			brow.visible = on
			# Inner ends raised: the universal "sad" brow.
			# Left brow's inner end is its +x end: a counter-clockwise turn lifts it.
			brow.rotation = (-0.35 if brow_name == "ceja_izq" else 0.35) if on else 0.0


func _start_breathing() -> void:
	if not Motion.enabled():
		return
	_breath = create_tween().set_loops()
	_breath.tween_property(_root, "scale", Vector2(1.0, BREATH_SCALE), BREATH_SECONDS / 2.0).set_trans(Tween.TRANS_SINE)
	_breath.tween_property(_root, "scale", Vector2.ONE, BREATH_SECONDS / 2.0).set_trans(Tween.TRANS_SINE)


func _hop() -> void:
	if not Motion.enabled():
		return
	_pose = create_tween()
	_pose.tween_property(_root, "position:y", -28.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pose.tween_property(_root, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _wave() -> void:
	var arm: Node2D = _parts.get("brazo_der")
	if arm == null:
		return
	var up: float = _def.get("wave_up", -2.6)
	if not Motion.enabled():
		arm.rotation = up
		return
	_pose = create_tween()
	_pose.tween_property(arm, "rotation", up, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for i in 3:
		_pose.tween_property(arm, "rotation", up + 0.3, 0.14).set_trans(Tween.TRANS_SINE)
		_pose.tween_property(arm, "rotation", up - 0.1, 0.14).set_trans(Tween.TRANS_SINE)
	_pose.tween_property(arm, "rotation", _rest_rot["brazo_der"], 0.25).set_trans(Tween.TRANS_SINE)


func _chew() -> void:
	_set_mouth("happy")
	_pose = create_tween()
	for i in 4:
		_pose.tween_callback(_set_mouth.bind("closed")).set_delay(0.13)
		_pose.tween_callback(_set_mouth.bind("happy")).set_delay(0.13)


func _kill_pose() -> void:
	if _pose and _pose.is_valid():
		_pose.kill()


func _on_talk_flap() -> void:
	if not is_talking():
		_talk_timer.stop()
		_set_mouth(_resting_mouth())
		return
	var mouth: Sprite2D = _parts.get("boca")
	var talk_path: String = _def["mouth"]["talk"]
	var showing_talk := mouth != null and mouth.texture != null and mouth.texture.resource_path == talk_path
	_set_mouth(_resting_mouth() if showing_talk else "talk")


func _on_blink() -> void:
	_blink_timer.start(_rng.randf_range(2.5, 5.0))
	if state == &"contento" or state == &"bailar" or state == &"sorpresa":
		return
	var eyes: Array = []
	for eye_name in ["ojo_izq", "ojo_der"]:
		if _parts.has(eye_name):
			eyes.append(_parts[eye_name])
	if eyes.is_empty():
		return
	var t := create_tween().set_parallel()
	for eye in eyes:
		t.tween_property(eye, "scale:y", 0.12, 0.06)
	t.chain().tween_interval(0.06)
	t.set_parallel()
	for eye in eyes:
		t.tween_property(eye, "scale:y", 1.0, 0.08)
