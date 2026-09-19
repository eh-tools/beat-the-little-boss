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
	var max_contact_jump := 0.0
	var minimum_withdrawal := INF
	for role in ["male", "female"]:
		for stage in range(4):
			for weapon in ["hammer", "gloves"]:
				for critical in [false, true]:
					for direction in [-1, 1]:
						pet.capture_pose(role, stage)
						var resting_frame: int = pet._frame_index
						var contact := 0.17 if critical else 0.06
						var duration := 0.7 if critical else 0.35
						pet.play_attack({"character": role, "weapon": weapon, "critical": critical, "direction": direction, "stage": stage, "progress": stage * 9 + 1, "terminal": false, "finale": false, "duration": duration})
						var label := "%s stage %d %s critical=%s direction=%d" % [role, stage, weapon, critical, direction]
						pet._elapsed = contact - 0.001
						pet._pose(0.0)
						check(pet._frame_index == resting_frame, "no damage-pose pop before contact: " + label)
						var before_rotation: float = pet._bones.hip.rotation
						pet._elapsed = contact + 0.001
						pet._pose(0.0)
						max_contact_jump = maxf(max_contact_jump, absf(pet._bones.hip.rotation - before_rotation))
						check(absf(pet._bones.hip.rotation - before_rotation) < 0.01, "body recoil starts continuously at contact: " + label)
						pet._elapsed = contact + 0.08
						pet._pose(0.0)
						check(absf(pet._bones.hip.rotation) > 0.05, "smooth recoil retains a strong impact: " + label)
						var contact_weapon: Vector2 = pet._weapon_bone.position
						pet._elapsed = contact + 0.15 + (duration - contact - 0.15) * 0.65
						pet._pose(0.0)
						minimum_withdrawal = minf(minimum_withdrawal, pet._weapon_bone.position.distance_to(contact_weapon))
						check(pet._weapon_bone.position.distance_to(contact_weapon) > 8.0, "weapon visibly withdraws after contact: " + label)
						check(pet._weapon.modulate.a > 0.1, "recovery fills the attack instead of leaving an invisible cooldown: " + label)
						pet._elapsed = duration - 0.001
						pet._pose(0.0)
						check(pet._frame_index == resting_frame, "damage pose settles before the next attack: " + label)
						check(absf(pet._bones.hip.rotation) < 0.001 and pet._weapon.modulate.a < 0.01, "body and weapon finish without snapping: " + label)
	pet.capture_pose("female", 0)
	pet._time = 11.5
	pet._pose(0.0)
	var sip_wrist: Vector2 = pet._bones.right_wrist.global_position
	pet.play_attack({"character": "female", "weapon": "hammer", "critical": false, "direction": 1, "stage": 0, "progress": 1, "terminal": false, "finale": false, "duration": 0.35})
	check(pet._bones.right_wrist.global_position.distance_to(sip_wrist) < 0.1, "interrupting coffee preserves the hand position on the first attack frame")
	var previous: Vector2 = pet._bones.right_wrist.global_position
	var previous_elbow: Vector2 = pet._bones.right_forearm.global_position
	var max_hand_step := 0.0
	var max_elbow_step := 0.0
	for tick in range(1, 22):
		pet._elapsed = float(tick) / 60.0
		pet._pose(0.0)
		var current: Vector2 = pet._bones.right_wrist.global_position
		max_hand_step = maxf(max_hand_step, current.distance_to(previous))
		max_elbow_step = maxf(max_elbow_step, pet._bones.right_forearm.global_position.distance_to(previous_elbow))
		previous = current
		previous_elbow = pet._bones.right_forearm.global_position
	check(max_hand_step < 15.0, "interrupted coffee hand returns through an arc without teleporting (max step %.2f)" % max_hand_step)
	check(max_elbow_step < 15.0, "interrupted coffee elbow never flips across the shoulder (max step %.2f)" % max_elbow_step)
	pet.capture_pose("male", 0)
	pet._time = 10.5
	pet._pose(0.0)
	pet.play_attack({"character": "male", "weapon": "gloves", "critical": false, "direction": 1, "stage": 0, "progress": 1, "terminal": false, "finale": false, "duration": 0.35})
	pet._elapsed = 0.349
	pet._pose(0.0)
	var settled_frame: int = pet._frame_index
	pet._elapsed = 0.35
	pet._pose(0.0)
	check(pet._frame_index == settled_frame, "interrupted smoking does not jump back to a raised hand at attack completion")
	pet.queue_free()
	await process_frame
	print("Motion metrics: contact rotation step %.6f rad; minimum weapon withdrawal %.2f px; interrupted hand/elbow max steps %.2f/%.2f px" % [max_contact_jump, minimum_withdrawal, max_hand_step, max_elbow_step])
	if failures == 0: print("attack motion tests passed")
	quit(failures)
