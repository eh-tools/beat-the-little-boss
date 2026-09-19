extends SceneTree

const View = preload("res://src/pet_view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1020, 850)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("efe6d1"))
	var times := [0.0, 9.8, 10.3, 11.5, 12.6, 14.0]
	var labels := ["REST", "PICK UP", "LIFT", "SIP", "LOWER", "RESTORED"]
	for index in range(times.size()):
		var pet := View.new()
		root.add_child(pet)
		pet.scale = Vector2.ONE * 2
		pet.position = Vector2(10 + (index % 3) * 340, 45 + (index / 3) * 415)
		pet.capture_pose("female", 0)
		pet._time = times[index]
		pet._pose(0.0)
		var label := Label.new()
		label.text = "%s / %.1fs" % [labels[index], times[index]]
		label.position = pet.position - Vector2(0, 26)
		label.add_theme_color_override("font_color", Color("494454"))
		label.add_theme_font_size_override("font_size", 16)
		root.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.scratch/desktop-pet/female-coffee-rig.png")
	print("Female coffee rig captured from Godot renderer.")
	quit()
