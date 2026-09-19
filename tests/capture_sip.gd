extends SceneTree

const View = preload("res://src/pet_view.gd")

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(384, 212)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("efe6d1"))
	var pet := View.new()
	root.add_child(pet)
	pet.position = Vector2(112, 16)
	var male := OS.get_cmdline_user_args().has("--male")
	pet.capture_pose("male" if male else "female", 0)
	pet._time = 0.0 if male else (PI / 2.0 + 1.0) / 1.15
	pet._pose(0.0)
	var label := Label.new()
	label.text = "SMOKE BREAK" if male else "COFFEE BREAK"
	label.position = Vector2(12, 10)
	label.add_theme_color_override("font_color", Color("494454"))
	label.add_theme_font_size_override("font_size", 13)
	root.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.scratch/desktop-pet/%s-closeup.png" % ("smoke" if male else "sip"))
	print("Idle prop captured from Godot renderer.")
	quit()
