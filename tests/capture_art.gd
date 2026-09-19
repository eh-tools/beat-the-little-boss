extends SceneTree

const View = preload("res://src/pet_view.gd")


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	root.size = Vector2i(880, 430)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color("efe6d1"))
	var gallery := Node2D.new()
	root.add_child(gallery)
	var labels := ["01 / UNBOTHERED", "02 / NOT AMUSED", "03 / BAD DAY", "04 / OVERTIME?", "05 / NO MORE!"]
	for row in range(2):
		for stage in range(5):
			var pet := View.new()
			gallery.add_child(pet)
			pet.position = Vector2(10 + stage * 174, 24 + row * 210)
			pet.capture_pose("male" if row == 0 else "female", stage)
			var label := Label.new()
			label.text = labels[stage]
			label.position = Vector2(14 + stage * 174, 7 + row * 210)
			label.add_theme_color_override("font_color", Color("494454"))
			label.add_theme_font_size_override("font_size", 10)
			gallery.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.scratch/desktop-pet/art-gallery.png")
	print("Art gallery captured from Godot renderer.")
	quit()
