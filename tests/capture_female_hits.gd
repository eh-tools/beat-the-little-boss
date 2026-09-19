extends SceneTree

const View = preload("res://src/pet_view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1700, 980)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("efe6d1"))
	for row in range(2):
		for stage in range(5):
			var pet := View.new()
			root.add_child(pet)
			pet.position = Vector2(10 + stage * 340, 40 + row * 480)
			pet.scale = Vector2.ONE * 2
			pet.capture_pose("female", stage)
			pet.play_attack({"character": "female", "weapon": "hammer" if row == 0 else "gloves", "direction": 1 if row == 0 else -1, "stage": stage, "progress": stage * 9, "critical": row == 1, "terminal": stage == 4, "finale": false, "duration": 0.7 if row == 1 else 0.35})
			pet._elapsed = 0.17
			pet._pose(0.0)
			var label := Label.new()
			label.text = "%s / STAGE %d" % ["HAMMER" if row == 0 else "CRITICAL GLOVE", stage]
			label.position = pet.position - Vector2(0, 26)
			label.add_theme_color_override("font_color", Color("494454"))
			label.add_theme_font_size_override("font_size", 16)
			root.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var suffix := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	root.get_texture().get_image().save_png("res://.scratch/desktop-pet/female-hit-arms-%s.png" % suffix)
	print("Female hit arms captured from Godot renderer.")
	quit()
