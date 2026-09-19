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
	pet.capture_pose("female", 0)
	check(pet._parts.right_arm.visible and pet._parts.right_forearm.visible, "coffee has a visible shoulder-to-hand chain")
	check(pet._parts.left_arm.visible and pet._parts.left_forearm.visible, "the resting arm stays connected to the torso")
	check(pet._idle_prop.visible and not pet._props.cup.visible, "female idle displays exactly one articulated coffee cup")
	var resting_cup: Vector2 = pet._idle_prop.global_position
	check(resting_cup.distance_to(pet._props.cup.global_position) < 0.01, "held and desk cups share the same resting anchor")
	var resting_texture: Texture2D = pet._icon_body.texture
	var held_frames := true
	var connected := true
	var clickable_arm := true
	var cup_blocks_hits := true
	var max_step := 0.0
	var max_elbow_step := 0.0
	var previous_grip: Vector2 = pet._idle_prop.to_global(Vector2(15, 9))
	var previous_elbow: Vector2 = pet._bones.right_forearm.global_position
	pet._capture = false
	for tick in range(841):
		pet._time = float(tick) / 60.0
		pet._pose(0.0)
		held_frames = held_frames and pet._icon_body.texture == resting_texture
		var grip: Vector2 = pet._idle_prop.to_global(Vector2(15, 9))
		var wrist: Vector2 = pet._bones.right_forearm.to_global(Vector2(0, 27))
		var shoulder: Vector2 = pet._icon_body.to_global(Vector2(106, 128))
		connected = connected and grip.distance_to(wrist) < 0.01
		connected = connected and pet._bones.right_arm.global_position.distance_to(shoulder) < 0.01
		connected = connected and pet._bones.right_arm.to_global(Vector2(0, 24)).distance_to(pet._bones.right_forearm.global_position) < 0.01
		max_step = maxf(max_step, grip.distance_to(previous_grip))
		max_elbow_step = maxf(max_elbow_step, pet._bones.right_forearm.global_position.distance_to(previous_elbow))
		previous_grip = grip
		previous_elbow = pet._bones.right_forearm.global_position
		var sleeve: Vector2 = pet.to_local(pet._parts.right_arm.to_global(Vector2(9, 10)))
		clickable_arm = clickable_arm and pet.hit_test(sleeve)
		var cup_center: Vector2 = pet.to_local(pet._idle_prop.to_global(Vector2(7, 10)))
		cup_blocks_hits = cup_blocks_hits and pet.solid_test(cup_center) and not pet.hit_test(cup_center)
	check(held_frames, "coffee movement does not swap jittered full-body frames or baked cup fragments")
	check(connected, "shoulder and coffee grip stay attached for every frame of the 14-second cycle")
	check(max_step <= 2.0, "coffee lift, lowering and loop wrap are continuous (max step %.2f)" % max_step)
	check(max_elbow_step <= 2.0, "elbow bends smoothly without flipping across the shoulder (max step %.2f)" % max_elbow_step)
	check(clickable_arm, "visible animated sleeve pixels remain attackable")
	check(cup_blocks_hits, "the moving cup is solid and occludes body hits")
	pet._time = 11.5
	pet._pose(0.0)
	var mouth: Vector2 = pet._icon_body.to_global(Vector2(80, 109))
	check(pet._idle_prop.to_global(Vector2(5, 3)).distance_to(mouth) <= 1.0, "coffee rim reaches the actual framed mouth")
	pet._time = 14.0
	pet._capture = true
	pet._pose(0.0)
	check(pet._idle_prop.global_position.distance_to(resting_cup) < 0.01, "coffee returns to its resting position before the loop repeats")
	for zoom in [1.0, 1.5, 2.0]:
		pet.scale = Vector2.ONE * zoom
		pet.position = Vector2(16, 16)
		for time in [0.0, 10.0, 11.5, 12.5, 14.0]:
			pet._time = time
			pet._pose(0.0)
			check(pet._idle_prop.to_global(Vector2(15, 9)).distance_to(pet._bones.right_wrist.global_position) < 0.01, "coffee grip stays attached at %.1fx scale" % zoom)
			var finger: Vector2 = pet.to_local(pet._parts.right_hand.to_global(Vector2(8, 5)))
			check(pet.hit_test(finger), "fingers in front of the cup remain attackable at %.1fx scale" % zoom)
			if time == 11.5:
				check(pet._idle_prop.to_global(Vector2(5, 3)).distance_to(pet._icon_body.to_global(Vector2(80, 109))) < 0.01, "cup rim meets mouth at %.1fx scale" % zoom)
	pet.scale = Vector2.ONE
	pet.position = Vector2.ZERO
	for role in ["male", "female"]:
		for stage in range(5):
			pet.capture_pose(role, stage)
			var coffee_idle: bool = role == "female" and stage == 0
			check(pet._idle_prop.visible == coffee_idle, "%s stage %d has no stale held cup" % [role, stage])
			var articulated_arms: bool = role == "female" and stage < 4
			check(pet._parts.right_arm.visible == articulated_arms, "%s stage %d uses the appropriate visible arms" % [role, stage])
	for zoom in [1.0, 2.0]:
		pet.scale = Vector2.ONE * zoom
		for stage in range(4):
			for weapon in ["hammer", "gloves"]:
				for direction in [-1, 1]:
					for critical in [false, true]:
						check_attack_arms(pet, stage, weapon, direction, critical)
	pet.scale = Vector2.ONE
	pet.capture_pose("female", 0)
	pet._time = 11.5
	pet._pose(0.0)
	pet.play_attack({"character": "female", "weapon": "hammer", "direction": 1, "stage": 0, "progress": 1, "critical": false, "terminal": false, "finale": false, "duration": 0.35})
	check(not pet._idle_prop.visible and pet._props.cup.visible, "an attack interrupts the sip without duplicating the cup")
	pet._elapsed = 1.0
	pet._pose(0.0)
	check(pet._idle_prop.global_position.distance_to(resting_cup) < 0.01, "after a hit coffee resumes from rest instead of jumping back to the mouth")
	pet.queue_free()
	await process_frame
	if failures == 0: print("female idle tests passed")
	quit(failures)

func check_attack_arms(pet: Node2D, stage: int, weapon: String, direction: int, critical: bool) -> void:
	pet.capture_pose("female", 0)
	pet._time = 11.5
	pet._pose(0.0)
	var duration := 0.7 if critical else 0.35
	pet.play_attack({"character": "female", "weapon": weapon, "direction": direction, "stage": stage, "progress": stage * 9 + 1, "critical": critical, "terminal": false, "finale": false, "duration": duration})
	var visible := true
	var attached := true
	var clickable := true
	var cup_on_desk := true
	var left_start := Vector2.ZERO
	var recoil := 0.0
	# Include attack startup, contact, recoil, the last active frame and injured rest.
	for time in [0.0, 0.03, 0.06, 0.17, 0.28, duration - 0.001, duration, 1.0]:
		pet._elapsed = time
		pet._pose(0.0)
		for side in ["left", "right"]:
			for segment in ["arm", "forearm", "hand"]:
				var part: Sprite2D = pet._parts[side + "_" + segment]
				visible = visible and part.is_visible_in_tree()
			var arm: Bone2D = pet._bones[side + "_arm"]
			var forearm: Bone2D = pet._bones[side + "_forearm"]
			var hand: Bone2D = pet._bones[side + "_wrist"]
			var shoulder: Vector2 = pet._icon_body.to_global(Vector2(52 if side == "left" else 106, 128))
			attached = attached and arm.global_position.distance_to(shoulder) < 0.01
			attached = attached and arm.to_global(Vector2(0, 24)).distance_to(forearm.global_position) < 0.01
			attached = attached and forearm.to_global(Vector2(0, 27)).distance_to(hand.global_position) < 0.01
			var sleeve: Vector2 = pet.to_local(pet._parts[side + "_arm"].to_global(Vector2(9, 10)))
			clickable = clickable and pet._pixel_hit(pet._parts[side + "_arm"], sleeve) and pet.hit_test(sleeve)
		if time < duration or stage > 0:
			cup_on_desk = cup_on_desk and not pet._idle_prop.visible and pet._props.cup.visible
		if time == 0.0:
			left_start = pet._bones.left_wrist.global_position
		elif time < duration:
			recoil = maxf(recoil, pet._bones.left_wrist.global_position.distance_to(left_start))
	var label := "stage %d %s direction %d critical=%s zoom=%.1f" % [stage, weapon, direction, critical, pet.scale.x]
	check(visible, "both arms and hands remain visible during and after a hit: " + label)
	check(attached, "hit arms stay joined to shoulders, elbows and wrists: " + label)
	check(clickable, "visible hit sleeves remain attackable: " + label)
	check(cup_on_desk, "hit arms do not resume sipping or duplicate the cup: " + label)
	check(recoil > 1.0, "hands follow body recoil during a hit: " + label)
