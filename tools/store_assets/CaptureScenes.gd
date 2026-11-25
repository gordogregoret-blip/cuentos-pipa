class_name CaptureScenes
extends RefCounted
## Arma la pantalla pedida para tools/store_assets/capture.gd.


static func make(kind: String, args: Dictionary) -> Node:
	match kind:
		"story":
			var p: Control = load("res://src/ui/StoryPlayer.tscn").instantiate()
			p.ready.connect(func() -> void:
				var resume := {}
				if args.has("page"):
					resume = {"page": args["page"], "history": _history(args), "flags": []}
				(p as StoryPlayer).open(String(args.get("story", "res://stories/dino")), resume))
			return p
	push_error("escena desconocida: " + kind)
	return Node.new()


static func _history(args: Dictionary) -> Array:
	var h: Array = []
	for i in int(args.get("step", "1")) - 1:
		h.append(args.get("page", "p1"))
	return h
