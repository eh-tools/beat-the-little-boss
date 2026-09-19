extends SceneTree

const View = preload("res://src/pet_view.gd")
var failures := 0

func _init() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)

func run() -> void:
	var pet := View.new()
	root.add_child(pet)
	pet.capture_pose("male", 0)
	check(pet._icon_body.visible and not pet._parts.head.visible, "male uses the icon-derived sprite body")
	check(pet._male_frames.size() == 32, "male icon animation loads all 32 sprite frames")
	check(pet._icon_body.scale == Vector2(0.7625, 0.7625), "male layered body keeps the approved compact scale")
	check(pet._icon_body.region_rect.end.y == 172, "male idle crop retains the complete seated torso and forearms")
	check(pet._male_desk_top.visible and pet._male_desk_front.visible, "male desk uses separate top and cabinet foreground layers")
	check(pet._props.cup.position == Vector2(127, 118), "male coffee cup rests at the approved desk position")
	check(not pet._pixel_hit(pet._icon_body, Vector2(82, 144)), "male body cannot appear below the desk")
	check(pet._male_desk_top.get_index() < pet._rig.get_index(), "male seated hands draw on top of the desktop")
	check(pet._pixel_hit(pet._icon_body, Vector2(55, 126)), "male resting hand reaches the desktop")
	check(pet.hit_test(Vector2(55, 126)), "visible resting hand remains clickable on the desktop")
	var idle_height := male_torso_height(pet)
	for frame in range(16, 28):
		pet._set_male_frame(frame)
		var ratio := male_torso_height(pet) / idle_height
		check(ratio >= 0.95 and ratio <= 1.05, "male hit frame %d keeps idle body size (ratio %.2f)" % [frame, ratio])
	pet._set_male_frame(0)
	check(pet._icon_body.scale == Vector2(0.7625, 0.7625), "returning from a hit preserves the approved idle scale")
	for frame in range(16):
		pet._set_male_frame(frame)
		check(pet._icon_body.scale == Vector2(0.7625, 0.7625) and pet._icon_body.position.x == -62, "idle/smoking frame %d preserves its approved size and center" % frame)
	for frame in range(4):
		pet._set_male_frame(frame)
		var collar := pet.to_local(pet._icon_body.to_global(Vector2(80, 140)))
		check(125.0 - collar.y >= 18.0, "male idle frame %d leaves the chest above the desktop instead of burying the chin" % frame)
	for stage in range(4):
		pet.capture_pose("male", stage)
		check_desk_contact(pet, "idle stage %d" % stage)
	pet.capture_pose("male", 0)
	pet._capture = false
	for frame in range(28):
		for time in [PI / 4.2, 3.0 * PI / 4.2]:
			pet._time = time
			pet._pose(0.0)
			pet._set_male_frame(frame)
			check_desk_contact(pet, "frame %02d breathing at %.2f" % [frame, time])
			if frame >= 4 and frame <= 7:
				check_smoking_crop(pet)
	pet.capture_pose("male", 0)
	pet._capture = false
	pet._time = 0.0
	pet._pose(0.0)
	var idle_hip_position: Vector2 = pet._bones.hip.position
	var idle_frame := pet._male_frame
	pet._time = PI / (2.1 * 2.0)
	pet._pose(0.0)
	check(pet._icon_body.get_parent() == pet._bones.hip and pet._bones.hip.position != idle_hip_position, "male icon sprite follows idle breathing")
	check(not pet._icon_idle_prop.visible, "male smoking is drawn by the sprite frames")
	check(pet._male_frame == idle_frame, "male idle pose holds instead of twitching through full-body frames")
	pet._time = 10.5
	pet._pose(0.0)
	check(pet._male_frame >= 4 and pet._male_frame <= 10, "male smoking sequence starts after a calm idle interval")
	pet.play_attack(attack("male", "hammer", 1, 0))
	pet._elapsed = 0.17
	pet._pose(0.0)
	check(absf(pet._icon_body.global_rotation) > 0.001, "male icon sprite recoils on hit")
	check(pet._male_frame >= 16 and pet._male_frame < 20, "male hit uses a sustained flinch frame")
	check(is_equal_approx(male_torso_height(pet), idle_height), "playing an attack preserves the idle body size")
	check(pet._male_desk_top.position == Vector2(5, 119) and pet._male_desk_front.position == Vector2(5, 136), "male desk layers stay fixed during a hit")
	check(pet._props.monitor.position == Vector2(7, 101), "male monitor stays on the desk during a hit")
	check(pet._props.keyboard.position == Vector2(61, 120), "male keyboard stays on the desk during a hit")
	check(pet._props.cup.position == Vector2(127, 118), "male coffee cup stays on the desk during a hit")
	pet.capture_pose("male", 2)
	check(pet._male_frame >= 20 and pet._male_frame < 24, "male injured stage uses persistent damage frames")
	check(is_equal_approx(male_torso_height(pet), idle_height), "persistent injury preserves the idle body size")
	var injured_frame := pet._male_frame
	pet._capture = false
	pet._time = 1.0
	pet._pose(0.0)
	check(pet._male_frame == injured_frame, "male persistent injury pose does not cycle and twitch")
	pet.capture_pose("male", 4)
	check(pet._male_frame >= 28 and pet._male_frame < 32, "male terminal state uses kneeling damage frames")
	check(not pet._icon_body.region_enabled, "male terminal pose keeps the full kneeling sprite")
	check(not pet._male_desk_top.visible and not pet._male_desk_front.visible, "male terminal pose restores the broken full desk")
	check(pet._icon_body.scale == Vector2.ONE, "male terminal pose restores the full-size kneeling frame")
	pet.capture_pose("male", 0)
	for damage_stage in [1, 2, 3]:
		pet.play_attack(attack("male", "hammer", 1, damage_stage))
		pet._elapsed = 0.17
		pet._pose(0.0)
		var damage_start: int = 16 + (damage_stage - 1) * 4
		check(pet._male_frame >= damage_start and pet._male_frame < damage_start + 4, "male stage %d hit keeps matching damage frames" % damage_stage)
	pet.capture_pose("male", 0)
	var point := Vector2(82, 56)
	check(pet.hit_test(point), "visible face can be hit")
	for key in ["cup", "papers", "ashtray"]:
		var sprite: Sprite2D = pet._props[key]
		var original := sprite.position
		sprite.position = point - Vector2(7, 5)
		check(not pet.hit_test(point), "opaque foreground %s blocks a hidden body hit" % key)
		sprite.position = original
	check(not pet.hit_test(Vector2(30, 145)), "desk cannot be attacked")
	check(not pet.solid_test(Vector2.ZERO), "transparent corner passes through")
	pet.capture_pose("female", 0)
	check(pet._icon_body.visible and not pet._parts.head.visible, "female uses the shared frame body")
	check(pet._character_frames["female"].size() == 32, "female animation loads all 32 sprite frames")
	check(pet._frame_index >= 0 and pet._frame_index <= 10, "female idle selects a coffee frame")
	for stage in range(4):
		pet.capture_pose("female", stage)
		check_framed_desk_contact(pet, "female seated stage %d" % stage)
	for stage in [1, 2, 3]:
		pet.capture_pose("female", stage)
		var female_damage_start: int = 16 + (stage - 1) * 4
		check(pet._frame_index >= female_damage_start and pet._frame_index < female_damage_start + 4, "female stage %d uses matching damage frames" % stage)
	pet.capture_pose("female", 4)
	check(pet._frame_index >= 28 and pet._frame_index < 32, "female terminal selects kneeling frames")
	check(not pet._icon_body.region_enabled, "female terminal keeps the full kneeling frame")
	check(not pet._male_desk_top.visible and not pet._male_desk_front.visible, "female terminal restores the broken full desk")
	check(pet._pixel_hit(pet._icon_body, Vector2(81, 154)), "female terminal keeps a visible lower kneeling pose")
	pet.capture_pose("female", 0)
	check(not pet._pixel_hit(pet._icon_body, Vector2(81, 145)), "female seated body stays hidden behind the cabinet")
	pet.capture_pose("male", 0)
	pet._time = 0.0
	pet._pose(0.0)
	var cigarette_mouth := pet.to_local(pet._idle_prop.to_global(Vector2(1, 3)))
	check(pet._idle_prop.get_parent() == pet._bones.head, "male cigarette stays attached to the head, not the hand")
	check(cigarette_mouth.distance_to(Vector2(81, 78)) <= 7.0, "male cigarette starts at the mouth")
	for role in ["male", "female"]:
		for stage in range(5):
			pet.capture_pose(role, stage)
			check_connected(pet, "%s idle stage %d" % [role, stage])
			for weapon in ["hammer", "gloves"]:
				for direction in [-1, 1]:
					pet.play_attack(attack(role, weapon, direction, stage))
					for time in [0.0, 0.03, 0.06, 0.15, 0.28]:
						pet._elapsed = time
						pet._pose(0.0)
						check_connected(pet, "%s %s stage %d at %.2f" % [role, weapon, stage, time])
						if role == "male" and stage < 4:
							check_desk_contact(pet, "%s stage %d direction %d at %.2f" % [weapon, stage, direction, time])
				var critical := attack(role, weapon, 0, stage)
				critical.critical = true
				critical.duration = 0.7
				pet.play_attack(critical)
				for time in [0.0, 0.085, 0.17, 0.3, 0.4]:
					pet._elapsed = time
					pet._pose(0.0)
					check_connected(pet, "%s critical %s stage %d at %.2f" % [role, weapon, stage, time])
					if role == "male" and stage < 4:
						check_desk_contact(pet, "critical %s stage %d at %.2f" % [weapon, stage, time])
	for direction in [-1, 1]:
		pet.capture_pose("female", 0)
		pet.play_attack(attack("female", "gloves", direction, 0))
		var start: Vector2 = pet._weapon_bone.position
		var start_angle: float = pet._weapon_bone.rotation
		pet._elapsed = 0.03
		pet._pose(0.0)
		var middle: Vector2 = pet._weapon_bone.position
		pet._elapsed = 0.06
		pet._pose(0.0)
		var contact: Vector2 = pet._weapon_bone.position
		check(absf((middle - start).cross(contact - start)) / start.distance_to(contact) > 3.0, "hook follows an arc instead of a straight slide")
		check(absf(pet._weapon_bone.rotation - start_angle) > 0.5, "hook rotates into side-on contact")
		var knuckles: Vector2 = Vector2.UP.rotated(pet._weapon_bone.rotation)
		check(knuckles.dot(Vector2(-direction, 0)) > 0.9, "hook knuckles point inward at contact")
		var guard: Node2D = pet._other_glove.get_parent()
		check((guard.position.x - 81) * direction < 0, "other glove guards on the opposite side")
		pet._elapsed = 0.28
		pet._pose(0.0)
		check(pet._weapon_bone.position.distance_to(contact) > 8, "hook withdraws after contact instead of fading in place")
	pet.queue_free()
	await process_frame
	if failures == 0: print("view tests passed")
	quit(failures)

func attack(role: String, weapon: String, direction: int, stage: int) -> Dictionary:
	return {"character": role, "weapon": weapon, "direction": direction, "stage": stage, "progress": stage * 9, "critical": false, "terminal": stage == 4, "finale": false, "duration": 0.35}

func male_torso_height(pet: Node2D) -> float:
	# Measure the continuous head/torso silhouette, ignoring detached impact marks.
	var body: Sprite2D = pet._icon_body
	var image: Image = body.texture.get_image()
	var bottom := int(body.region_rect.end.y)
	var top := bottom - 1
	while top > 0 and image.get_pixel(80, top - 1).a > 0.1:
		top -= 1
	return (bottom - top) * body.scale.y

func check_connected(pet: Node2D, label: String) -> void:
	check(pet._icon_body.visible and pet._pixel_hit(pet._icon_body, Vector2(80, 60)), "framed body stays opaque: " + label)

func check_desk_contact(pet: Node2D, label: String) -> void:
	# The seated torso must reach the opaque desktop, with no transparent strip.
	for x in [76, 80, 84]:
		var desk_y := 119
		while desk_y < 137 and not pet._pixel_hit(pet._male_desk_top, Vector2(x, desk_y)):
			desk_y += 1
		check(desk_y < 137, "desktop has an opaque contact surface: " + label)
		check(pet._pixel_hit(pet._icon_body, Vector2(x, desk_y - 1)), "male torso meets desktop at x=%d: %s" % [x, label])


func check_framed_desk_contact(pet: Node2D, label: String) -> void:
	check_desk_contact(pet, label)

func check_smoking_crop(pet: Node2D) -> void:
	var body: Sprite2D = pet._icon_body
	var strip_visible := false
	for y in range(22, 32):
		for x in range(20, 140):
			var point := pet.to_local(body.to_global(Vector2(x, y) - body.region_rect.position))
			strip_visible = strip_visible or pet._pixel_hit(body, point)
	check(not strip_visible, "smoking frame %d hides the stray sprite-sheet strip above the head" % pet._male_frame)
	# Region coordinates must agree with the displayed alpha mask, including empty pixels.
	var image: Image = body.texture.get_image()
	var mismatches := 0
	for y in range(0, int(body.region_rect.size.y), 4):
		for x in range(0, int(body.region_rect.size.x), 4):
			var local := Vector2(x + 0.5, y + 0.5)
			var source := Vector2i(local + body.region_rect.position)
			var point := pet.to_local(body.to_global(local))
			if pet._pixel_hit(body, point) != (image.get_pixelv(source).a > 0.1):
				mismatches += 1
	check(mismatches == 0, "smoking frame %d hit mask follows the cropped texture" % pet._male_frame)
