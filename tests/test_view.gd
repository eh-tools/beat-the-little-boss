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
	check(pet._icon_body.region_enabled, "male regular pose is clipped at the desk edge")
	check(pet._icon_body.region_rect == Rect2(0, 0, 160, 108), "male desk clip ends at the desk edge")
	check(not pet._pixel_hit(pet._icon_body, Vector2(82, 144)), "male body cannot appear below the desk")
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
	pet.capture_pose("male", 2)
	check(pet._male_frame >= 20 and pet._male_frame < 24, "male injured stage uses persistent damage frames")
	var injured_frame := pet._male_frame
	pet._capture = false
	pet._time = 1.0
	pet._pose(0.0)
	check(pet._male_frame == injured_frame, "male persistent injury pose does not cycle and twitch")
	pet.capture_pose("male", 4)
	check(pet._male_frame >= 28 and pet._male_frame < 32, "male terminal state uses kneeling damage frames")
	check(not pet._icon_body.region_enabled, "male terminal pose keeps the full kneeling sprite")
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
	check(not pet._icon_body.visible and pet._parts.head.visible, "female keeps the articulated sprite body")
	pet._time = (PI / 2.0 + 1.0) / 1.15
	pet._pose(0.0)
	var mouth := Vector2(81, 78)
	var cup_center := pet.to_local(pet._idle_prop.to_global(Vector2(8, 5)))
	check(cup_center.distance_to(mouth) <= 8.0, "female coffee reaches the mouth at the top of the sip")
	check(pet._bones.right_forearm.z_index > pet._bones.head.z_index, "sipping hand and cup draw in front of the face")
	pet.capture_pose("male", 0)
	pet._time = 0.0
	pet._pose(0.0)
	var cigarette_mouth := pet.to_local(pet._idle_prop.to_global(Vector2(1, 3)))
	check(pet._idle_prop.get_parent() == pet._bones.head, "male cigarette stays attached to the head, not the hand")
	check(cigarette_mouth.distance_to(mouth) <= 7.0, "male cigarette starts at the mouth")
	pet.capture_pose("female", 0)
	check(pet._idle_prop.get_parent() == pet._bones.right_forearm, "female cup remains attached to the drinking hand")
	var chin_image: Image = pet._tex("chin").get_image()
	check(chin_image.get_width() <= 12 and chin_image.get_height() <= 8, "chin injury is a local bruise, not a strip across the neck")
	check(pet._chin.position.x >= 0 and pet._chin.position.y <= -6, "chin injury sits on one side of the lower jaw")
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
				var critical := attack(role, weapon, 0, stage)
				critical.critical = true
				critical.duration = 0.7
				pet.play_attack(critical)
				for time in [0.0, 0.085, 0.17, 0.3, 0.4]:
					pet._elapsed = time
					pet._pose(0.0)
					check_connected(pet, "%s critical %s stage %d at %.2f" % [role, weapon, stage, time])
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

func check_connected(pet: Node2D, label: String) -> void:
	if pet.character == "male":
		check(pet._icon_body.visible and pet._pixel_hit(pet._icon_body, Vector2(80, 60)), "icon body stays opaque: " + label)
		return
	var chin: Vector2 = pet.to_local(pet._parts.head.to_global(Vector2(31, 59)))
	check(pet._pixel_hit(pet._parts.hip, chin), "chin stays connected to opaque collar: " + label)
