extends SceneTree

const View = preload("res://src/pet_view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1152, 896)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("efe6d1"))
	var times := [0.0, 0.03, 0.06, 0.18, 0.26, 0.34]
	for row in range(4):
		var role := "male" if row < 2 else "female"
		var direction := -1 if row % 2 == 0 else 1
		for column in range(times.size()):
			var pet := View.new()
			root.add_child(pet)
			pet.position = Vector2(16 + column * 192, 38 + row * 224)
			pet.capture_pose(role, 0)
			pet.play_attack({"character": role, "weapon": "gloves", "direction": direction, "stage": 0, "progress": 1, "critical": false, "terminal": false, "finale": false, "duration": 0.35})
			pet._elapsed = times[column]
			pet._pose(0.0)
			pet.queue_redraw()
			var label := Label.new()
			label.text = "%s / %s / %.2fs" % [role, "LEFT" if direction < 0 else "RIGHT", times[column]]
			label.position = Vector2(12 + column * 192, 10 + row * 224)
			label.add_theme_color_override("font_color", Color("494454"))
			label.add_theme_font_size_override("font_size", 12)
			root.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var tag := "before" if OS.get_cmdline_user_args().has("--before") else "after"
	root.get_texture().get_image().save_png("res://.scratch/desktop-pet/hooks-%s.png" % tag)
	print("Hook contact sheet captured: ", tag)
	quit()
