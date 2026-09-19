class_name PetView
extends Node2D

const ART := "res://assets/art/"
const MALE_BODY_HEIGHT := 180
const MALE_BODY_SCALE := 0.7625
const MALE_BODY_BASELINE := 130.0
const FRAME_CHARACTER_IDS := ["male", "female"]
var character := "male"
var state := {"stage": 0, "progress": 0, "bump": 0, "chin": 0}
var _textures: Dictionary = {}
var _images: Dictionary = {}
var _male_frames: Array[Texture2D] = []
var _male_body_heights: Array[int] = []
var _male_body_scales: Array[float] = []
var _male_frame := -1
var _frame_index := -1
var _character_frames: Dictionary = {}
var _character_body_heights: Dictionary = {}
var _character_body_scales: Dictionary = {}
var _body_sprites: Array[Sprite2D] = []
var _solid_sprites: Array[Sprite2D] = []
var _bones: Dictionary = {}
var _parts: Dictionary = {}
var _props: Dictionary = {}
var _chair: Sprite2D
var _desk: Sprite2D
var _male_desk_top: Sprite2D
var _male_desk_front: Sprite2D
var _icon_body: Sprite2D
var _icon_idle_prop: Sprite2D
var _rig: Skeleton2D
var _weapon_rig: Skeleton2D
var _weapon_bone: Bone2D
var _weapon: Sprite2D
var _other_glove: Sprite2D
var _bump: Sprite2D
var _chin: Sprite2D
var _idle_prop: Sprite2D
var _time := 0.0
var _elapsed := 10.0
var _event: Dictionary = {}
var _attack_from_frame := 0
var _attack_from_hands: Dictionary = {}
var _hovered := false
var _capture := false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_male_frames()
	_chair = _sprite(self, "chair_0", Vector2(21, 49))
	_icon_body = _sprite(self, "male_icon_body", Vector2.ZERO)
	_body_sprites.append(_icon_body)
	_icon_body.visible = false
	_icon_body.region_rect = Rect2(0, 0, 160, MALE_BODY_HEIGHT)
	_icon_idle_prop = _sprite(self, "cigarette", Vector2(78, 73), false)
	_icon_idle_prop.visible = false
	_rig = Skeleton2D.new()
	_rig.name = "LeaderSkeleton"
	add_child(_rig)
	_bone("hip", _rig, Vector2(81, 88))
	_icon_body.reparent(_bones.hip, false)
	_icon_body.position = Vector2(-81, -88)
	_icon_idle_prop.reparent(_bones.hip, false)
	_icon_idle_prop.position = Vector2(-3, -15)
	_set_male_frame(0)
	_bone("left_leg", _bones.hip, Vector2(-12, 34))
	_bone("right_leg", _bones.hip, Vector2(12, 34))
	_part("left_leg", "leg", Vector2(-9, 0))
	_part("right_leg", "leg", Vector2(-9, 0))
	_part("hip", "torso_0", Vector2(-24, -3))
	_bone("left_arm", _bones.hip, Vector2(-21, 5))
	_bone("left_forearm", _bones.left_arm, Vector2(0, 17))
	_bone("right_arm", _bones.hip, Vector2(21, 5))
	_bone("right_forearm", _bones.right_arm, Vector2(0, 17))
	for side in ["left", "right"]:
		_part(side + "_arm", "arm", Vector2(-9, -3))
		_part(side + "_forearm", "forearm", Vector2(-9, -3))
		_bone(side + "_wrist", _bones[side + "_forearm"], Vector2(0, 27))
		_bones[side + "_arm"].length = 24
		_bones[side + "_forearm"].length = 27
		_parts[side + "_hand"] = _sprite(_bones[side + "_wrist"], "female_forearm", Vector2(-8, -5))
		_body_sprites.append(_parts[side + "_hand"])
		_parts[side + "_hand"].region_enabled = true
		_parts[side + "_hand"].region_rect = Rect2(1, 14, 16, 12)
	_bone("head", _bones.hip, Vector2.ZERO)
	_part("head", "head_0", Vector2(-32, -59))
	_bump = _sprite(_bones.head, "bump", Vector2(-12, -64), false)
	_chin = _sprite(_bones.head, "chin", Vector2(3, -7), false)
	_idle_prop = _sprite(_bones.right_forearm, "cigarette", Vector2(2, 13))
	_desk = _sprite(self, "desk_0", Vector2(5, 108))
	_male_desk_top = _sprite(self, "desk_0", Vector2(5, 119), false)
	_male_desk_top.region_enabled = true
	_male_desk_top.region_rect = Rect2(0, 0, 150, 18)
	move_child(_male_desk_top, _rig.get_index())
	for prop in ["monitor", "keyboard", "papers", "cup", "ashtray"]:
		_props[prop] = _sprite(self, prop, Vector2.ZERO)
	_male_desk_front = _sprite(self, "desk_0", Vector2(5, 136), false)
	_male_desk_front.region_enabled = true
	_male_desk_front.region_rect = Rect2(0, 18, 150, 50)
	_weapon_rig = Skeleton2D.new()
	_weapon_rig.name = "WeaponSkeleton"
	add_child(_weapon_rig)
	_weapon_bone = Bone2D.new()
	_weapon_bone.name = "Swing"
	_weapon_bone.set_autocalculate_length_and_angle(false)
	_weapon_bone.length = 30
	_weapon_bone.rest = Transform2D.IDENTITY
	_weapon_rig.add_child(_weapon_bone)
	_weapon = _sprite(_weapon_bone, "hammer", Vector2(-24, -43), false)
	var guard := Bone2D.new()
	guard.name = "GuardGlove"
	guard.set_autocalculate_length_and_angle(false)
	guard.length = 16
	guard.rest = Transform2D.IDENTITY
	_weapon_rig.add_child(guard)
	guard.position = Vector2(125, 100)
	_other_glove = _sprite(guard, "gloves", Vector2(-24, -24), false)
	_other_glove.scale = Vector2(0.65, 0.65)
	_weapon_rig.visible = false
	_apply_art()
	_pose(0.0)


func _tex(key: String) -> Texture2D:
	if not _textures.has(key):
		_textures[key] = load(ART + key + ".png")
	return _textures[key]


func _load_male_frames() -> void:
	for id in FRAME_CHARACTER_IDS:
		_load_character_frames(id)


func _load_character_frames(id: String) -> void:
	var idle_height := 0.0
	var frames: Array[Texture2D] = []
	var heights: Array[int] = []
	var scales: Array[float] = []
	for index in range(32):
		frames.append(load(ART + id + "_frames/" + id + "_%02d.png" % index))
		if index >= 28:
			continue
		var image := frames[index].get_image()
		# Props and impact marks can extend beyond the torso, so anchor on its solid center.
		var bottom := image.get_height() - 1
		while bottom > 0:
			if image.get_pixel(70, bottom).a > 0.1 and image.get_pixel(80, bottom).a > 0.1 and image.get_pixel(90, bottom).a > 0.1:
				break
			bottom -= 1
		heights.append(bottom + 1)
		# Damage artwork is smaller within the same canvas. Match its continuous
		# head/torso height to idle, excluding detached impact marks above the hair.
		var top := bottom
		while top > 0 and image.get_pixel(80, top - 1).a > 0.1:
			top -= 1
		if index == 0:
			idle_height = (bottom + 1 - top) * MALE_BODY_SCALE
		scales.append(idle_height / (bottom + 1 - top) if index >= 16 else MALE_BODY_SCALE)
	_character_frames[id] = frames
	_character_body_heights[id] = heights
	_character_body_scales[id] = scales
	if id == "male":
		_male_frames = frames
		_male_body_heights = heights
		_male_body_scales = scales


func _set_male_frame(index: int) -> void:
	_set_character_frame(index)


func _set_character_frame(index: int) -> void:
	var frames = _character_frames.get(character, [])
	if frames.is_empty():
		return
	_frame_index = clampi(index, 0, frames.size() - 1)
	_male_frame = _frame_index if character == "male" else -1
	_icon_body.texture = frames[_frame_index]
	if int(state.get("stage", 0)) < 4:
		# These smoking frames contain a strip from the neighboring sheet row.
		var top := 32 if character == "male" and _frame_index >= 4 and _frame_index <= 7 else 0
		var bottom: int = _character_body_heights[character][_frame_index]
		var body_scale: float = _character_body_scales[character][_frame_index]
		_icon_body.region_rect = Rect2(0, top, 160, bottom - top)
		_icon_body.scale = Vector2.ONE * body_scale
		_icon_body.position = Vector2(-1.0 - 80.0 * body_scale, MALE_BODY_BASELINE - 88.0 - (bottom - top) * body_scale)


func _set_male_layers(stage: int) -> void:
	var layered := stage < 4
	var desk_texture := _tex("desk_" + str(stage))
	for sprite in [_male_desk_top, _male_desk_front]:
		sprite.visible = layered
		sprite.texture = desk_texture
	_desk.visible = not layered


func _update_male_frame(stage: int, active: bool, collapse: float, impact: float) -> void:
	var frame := 0
	if stage >= 4:
		frame = 28 if collapse < 0.25 else (29 if collapse < 0.55 else (30 if collapse < 0.85 else 31))
	elif active:
		var damage_start := 16 + clampi(stage - 1, 0, 2) * 4
		var contact := 0.17 if _event.get("critical", false) else 0.06
		if _elapsed < contact:
			frame = _attack_from_frame
		elif impact > 0.05 or _elapsed < contact + 0.15:
			frame = damage_start + 1
		else:
			frame = 0 if stage == 0 else damage_start + 1
	elif stage == 3:
		frame = 25
	elif stage == 2:
		frame = 21
	elif stage == 1:
		frame = 17
	elif character == "male":
		var idle_cycle := fmod(_time, 14.0)
		if idle_cycle < 4.0:
			frame = 0
		elif idle_cycle < 5.0:
			frame = 1
		elif idle_cycle < 8.0:
			frame = 0
		elif idle_cycle < 9.0:
			frame = 2
		elif idle_cycle < 10.0:
			frame = 3
		elif idle_cycle < 13.5:
			frame = 4 + clampi(int((idle_cycle - 10.0) / 0.5), 0, 6)
		else:
			frame = 0
	# Female idle keeps the clean body frame; its visible arm rig owns the sip.
	_set_character_frame(frame)


func _pose_female_arm(side: String, shoulder: Vector2, wrist: Vector2, bend: float, hand_angle: float) -> void:
	var upper: Bone2D = _bones[side + "_arm"]
	var forearm: Bone2D = _bones[side + "_forearm"]
	var hand: Bone2D = _bones[side + "_wrist"]
	upper.position = _bones.hip.to_local(shoulder)
	var target: Vector2 = _bones.hip.to_local(wrist) - upper.position
	# Two fixed-length links keep shoulder, elbow and wrist joined throughout the arc.
	var distance := clampf(target.length(), absf(upper.length - forearm.length) + 0.001, upper.length + forearm.length - 0.001)
	var shoulder_angle := target.angle() + bend * acos(clampf((distance * distance + upper.length * upper.length - forearm.length * forearm.length) / (2.0 * distance * upper.length), -1.0, 1.0))
	upper.rotation = shoulder_angle - PI / 2.0
	forearm.position = Vector2(0, upper.length)
	forearm.rotation = (upper.to_local(wrist) - forearm.position).angle() - PI / 2.0
	hand.position = Vector2(0, forearm.length)
	hand.global_rotation = global_rotation + hand_angle
	for segment in ["arm", "forearm", "hand"]:
		_parts[side + "_" + segment].visible = true
	var sleeve: Sprite2D = _parts[side + "_arm"]
	sleeve.scale = Vector2(0.85, 1.2)
	sleeve.position = Vector2(-7.65, -2.4)
	var cuff: Sprite2D = _parts[side + "_forearm"]
	cuff.texture = _tex("female_arm")
	cuff.scale = Vector2(0.8, 1.35)
	cuff.position = Vector2(-7.2, -2.7)
	_parts[side + "_hand"].texture = _tex("female_forearm")
	_parts[side + "_hand"].scale = Vector2.ONE * 0.65
	_parts[side + "_hand"].position = Vector2(-5.2, -3.25)


func _pose_female_arms(stage: int, active: bool) -> void:
	for side in ["left", "right"]:
		for segment in ["arm", "forearm", "hand"]:
			_parts[side + "_" + segment].visible = false
	if character != "female" or stage >= 4:
		return
	if stage > 0 or active:
		# Injury frames have no arms. Keep the rig attached and let hands recoil
		# with the hip while the cup stays on the desk. Terminal art has its own arms.
		var left_wrist := Vector2(-20, 38)
		var right_wrist := Vector2(57, 39)
		if active:
			var settle := smoothstep(0.0, 0.22, _elapsed)
			left_wrist = _attack_from_hands.left.lerp(left_wrist, settle)
			var hand_start: Vector2 = _attack_from_hands.right
			var hand_arc := Vector2(hand_start.x, right_wrist.y)
			right_wrist = hand_start.lerp(hand_arc, settle).lerp(hand_arc.lerp(right_wrist, settle), settle)
		_pose_female_arm("left", _icon_body.to_global(Vector2(52, 128)), _bones.hip.to_global(left_wrist), 1.0, _bones.hip.rotation)
		_pose_female_arm("right", _icon_body.to_global(Vector2(106, 128)), _bones.hip.to_global(right_wrist), -1.0, _bones.hip.rotation)
		return
	var cycle := fmod(_time, 14.0)
	var lift := smoothstep(9.0, 10.8, cycle) * (1.0 - smoothstep(11.8, 13.8, cycle))
	var tilt := lift * 0.15
	var mouth: Vector2 = _icon_body.to_global(Vector2(80, 109))
	var rest: Vector2 = _props.cup.to_global(Vector2(15, 9))
	var sip := mouth + Vector2(10, 6).rotated(global_rotation + tilt) * global_scale
	# Move inward before lifting, so the wrist does not pass through the shoulder.
	var arc := Vector2(sip.x - 10.0 * global_scale.x, rest.y)
	var wrist := rest.lerp(arc, lift).lerp(arc.lerp(sip, lift), lift)
	_pose_female_arm("left", _icon_body.to_global(Vector2(52, 128)), to_global(Vector2(61, 126)), 1.0, 0.0)
	_pose_female_arm("right", _icon_body.to_global(Vector2(106, 128)), wrist, -1.0, tilt)
	_idle_prop.visible = true
	_idle_prop.position = Vector2(-15, -9)
	_props.cup.visible = false


func _sprite(parent: Node, key: String, at: Vector2, solid: bool = true) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = _tex(key)
	sprite.centered = false
	sprite.position = at
	parent.add_child(sprite)
	if solid:
		_solid_sprites.append(sprite)
	return sprite


func _bone(key: String, parent: Node, at: Vector2) -> void:
	var bone := Bone2D.new()
	bone.name = key
	bone.position = at
	bone.set_autocalculate_length_and_angle(false)
	bone.length = 17
	bone.rest = bone.transform
	parent.add_child(bone)
	_bones[key] = bone


func _part(key: String, art: String, at: Vector2) -> void:
	var sprite := _sprite(_bones[key], character + "_" + art, at)
	_parts[key] = sprite
	_body_sprites.append(sprite)


func set_character(id: String, new_state: Dictionary) -> void:
	character = id
	state = new_state.duplicate()
	_event.clear()
	_elapsed = 10.0
	_time = 0.0
	if is_node_ready():
		_weapon_rig.visible = false
		_apply_art()
		_pose(0.0)


func _apply_art(furniture_stage: int = -1) -> void:
	var stage: int = int(state.get("stage", 0))
	var framed_layered := stage < 4
	_icon_body.visible = true
	_icon_body.region_enabled = framed_layered
	_icon_body.region_rect = Rect2(0, 0, 160, MALE_BODY_HEIGHT)
	_icon_body.scale = Vector2.ONE * MALE_BODY_SCALE if framed_layered else Vector2.ONE
	_icon_body.position = Vector2(-62, -78) if framed_layered else Vector2(-81, -88)
	_rig.visible = true
	_icon_idle_prop.visible = false
	_parts.head.texture = _tex(character + "_head_" + str(stage))
	_parts.hip.texture = _tex(character + "_torso_" + str(stage))
	for part in _parts.values():
		part.visible = false
	for side in ["left", "right"]:
		_parts[side + "_arm"].texture = _tex(character + "_arm")
		_parts[side + "_forearm"].texture = _tex(character + "_forearm")
		_parts[side + "_leg"].texture = _tex(character + "_leg")
	var furniture := stage if furniture_stage < 0 else furniture_stage
	_chair.texture = _tex("chair_" + str(furniture))
	_desk.texture = _tex("desk_" + str(furniture))
	_bump.visible = false
	_chin.visible = false
	var idle_parent: Node = _bones.head if character == "male" else _bones.right_wrist
	if _idle_prop.get_parent() != idle_parent:
		_idle_prop.reparent(idle_parent, false)
		idle_parent.move_child(_idle_prop, 0)
	_idle_prop.texture = _tex("cigarette" if character == "male" else "cup")


func play_attack(event: Dictionary) -> void:
	if event.get("character", character) != character:
		return
	_attack_from_frame = _frame_index
	for side in ["left", "right"]:
		_attack_from_hands[side] = _bones.hip.to_local(_bones[side + "_wrist"].global_position)
	_event = event.duplicate()
	_elapsed = 0.0
	_time = 0.0
	state.stage = event.stage
	state.progress = event.progress
	if event.critical:
		var injury := "bump" if event.weapon == "hammer" else "chin"
		state[injury] = int(state.get(injury, 0)) + 1
	_apply_art(3 if event.get("finale", false) else -1)
	_weapon.texture = weapon_texture(event.weapon)
	_weapon.position = Vector2(-24, -24) if event.weapon == "gloves" else Vector2(-24, -43)
	_weapon.flip_h = event.weapon == "gloves" and int(event.direction) > 0
	_weapon_rig.visible = true
	_other_glove.visible = event.weapon == "gloves"
	_pose(0.0)


func weapon_texture(weapon: String) -> Texture2D:
	return _tex("hammer" if weapon == "hammer" else "gloves")


func set_hovered(value: bool) -> void:
	_hovered = value
	for sprite in _body_sprites:
		sprite.modulate = Color(1.12, 1.1, 1.05) if value else Color.WHITE


func capture_pose(id: String, stage: int) -> void:
	_capture = true
	set_character(id, {"stage": stage, "progress": stage * 9, "bump": 1 if stage > 1 else 0, "chin": 1 if stage > 2 else 0})
	_pose(0.0)


func _process(delta: float) -> void:
	if _capture:
		return
	_time += delta
	_elapsed += delta
	_pose(delta)
	queue_redraw()


func _pose(_delta: float) -> void:
	var stage := int(state.get("stage", 0))
	var active := not _event.is_empty() and _elapsed < float(_event.get("duration", 0.35))
	var finale := active and bool(_event.get("finale", false))
	var collapse := clampf((_elapsed - 0.2) / 0.7, 0.0, 1.0) if finale else (1.0 if stage == 4 else 0.0)
	var impact := 0.0
	var breath := roundf(sin(_time * 2.1)) if not _capture else 0.0
	_bones.hip.position = Vector2(81, 88 + roundf(collapse * 25.0) + breath)
	_bones.hip.rotation = 0.0
	_bones.head.rotation = 0.0
	_bones.head.position = Vector2.ZERO
	_bones.left_leg.position = Vector2(-12, 34)
	_bones.right_leg.position = Vector2(12, 34)
	_bones.left_leg.rotation = 0.25 + collapse * 1.05
	_bones.right_leg.rotation = -0.25 - collapse * 1.05
	var kneeling := collapse > 0.55
	_rig.z_index = 1 if kneeling else 0
	for side in ["left", "right"]:
		_parts[side + "_leg"].texture = _tex(character + "_kneel_" + side if kneeling else character + "_leg")
	if kneeling:
		_bones.left_leg.position = Vector2(-13, 31)
		_bones.right_leg.position = Vector2(5, 31)
		_bones.left_leg.rotation = 0.0
		_bones.right_leg.rotation = 0.0
	_bones.left_arm.rotation = -0.35 - collapse * 0.15
	_bones.right_arm.rotation = 0.35 + collapse * 0.15
	_bones.left_forearm.rotation = -0.9 - collapse * 1.8
	_bones.right_forearm.rotation = 0.9 + collapse * 1.8
	_bones.right_arm.z_index = 0
	_bones.right_forearm.z_index = 0
	_idle_prop.position = Vector2(-1, -10)
	_idle_prop.visible = false
	_idle_prop.rotation = 0.0
	_chair.position = Vector2(21, 49)
	_desk.position = Vector2(5, 108)
	_chair.rotation = 0.0
	_desk.rotation = 0.0
	_props.monitor.position = Vector2(12, 83)
	_props.keyboard.position = Vector2(15, 119)
	_props.papers.position = Vector2(117, 117)
	_props.cup.position = Vector2(128, 102)
	_props.ashtray.position = Vector2(103, 120)
	for key in _props:
		_props[key].rotation = 0.0
		_props[key].visible = true
	if stage >= 1:
		_props.papers.position = Vector2(132, 147)
		_props.papers.rotation = 0.2
	if stage >= 2:
		_props.cup.position = Vector2(136, 149)
		_props.cup.rotation = 0.4
	if collapse > 0:
		_props.monitor.position = Vector2(12, 83).lerp(Vector2(7, 135), collapse).round()
		_props.monitor.rotation = -collapse * 0.28
		_props.keyboard.position = Vector2(15, 119).lerp(Vector2(37, 165), collapse).round()
		_props.keyboard.rotation = collapse * 0.15
		_props.ashtray.position = Vector2(103, 120).lerp(Vector2(115, 163), collapse).round()
		_props.papers.position = Vector2(130, 158)
		_props.cup.position = Vector2(136, 153)
	if stage < 4:
		_male_desk_top.position = Vector2(5, 119)
		_male_desk_front.position = Vector2(5, 136)
		_props.monitor.position = Vector2(7, 101)
		_props.keyboard.position = Vector2(61, 120)
		_props.papers.position = Vector2(112, 119)
		_props.papers.rotation = 0.0
		_props.cup.position = Vector2(123 if character == "female" else 127, 118)
		_props.cup.rotation = 0.0
		_props.ashtray.position = Vector2(103, 124)
	if finale:
		if collapse < 0.5:
			_desk.position.y += roundf(sin(_elapsed * 50) * 3)
			_chair.rotation = sin(_elapsed * 35) * 0.04
		else:
			_apply_art(4)
	if active:
		var critical := bool(_event.get("critical", false))
		var direction := float(_event.get("direction", 1))
		if direction == 0:
			direction = 1.0
		# Ease into impact, keep a short contact hold, then recover over the remaining action.
		var contact := 0.17 if critical else 0.06
		var hold_end := contact + 0.15
		var duration: float = _event.get("duration", 0.35)
		var retreat := smoothstep(hold_end, duration, _elapsed)
		impact = smoothstep(contact, contact + 0.045, _elapsed) * (1.0 - retreat)
		if bool(_event.get("terminal", false)):
			impact *= 0.25
		_bones.hip.rotation = -direction * impact * 0.08
		_bones.head.rotation = -direction * impact * 0.12
		# Rotate around the chin at the collar; lifting this pivot detaches the head.
		_bones.head.position.y += roundf(impact * 2.0) if _event.weapon == "hammer" else 0.0
		_bones.left_arm.rotation -= impact * 0.55
		_bones.right_arm.rotation += impact * 0.55
		var approach := smoothstep(0.0, contact, _elapsed)
		var visibility := smoothstep(0.0, 0.025, _elapsed) * (1.0 - smoothstep(0.5, 1.0, retreat))
		_weapon.modulate.a = visibility
		_other_glove.modulate.a = visibility * 0.8
		var guard: Bone2D = _other_glove.get_parent()
		guard.position = Vector2(81 - direction * 48, 104 + collapse * 25)
		guard.rotation = direction * 0.2
		_other_glove.flip_h = direction < 0
		if critical:
			if _event.weapon == "hammer":
				_weapon_bone.position = Vector2(82, -4).lerp(Vector2(82, 56), approach * (1.0 - retreat))
				_weapon_bone.rotation = -0.25 * (1.0 - approach * (1.0 - retreat))
			else:
				_weapon_bone.position = Vector2(82, 130).lerp(Vector2(82, 86), approach * (1.0 - retreat))
				_weapon_bone.rotation = -0.12
		elif _event.weapon == "gloves":
			# A wide wind-up curls into the cheek, with the knuckles turned inward.
			var start := Vector2(81 + direction * 60, 100 + collapse * 25)
			var arc := Vector2(81 + direction * 78, 38 + collapse * 25)
			var target := Vector2(81 + direction * 32, 68 + collapse * 25)
			_weapon_bone.position = start.lerp(arc, approach).lerp(arc.lerp(target, approach), approach)
			_weapon_bone.rotation = -direction * lerpf(0.25, PI / 2.0, approach)
			if retreat > 0:
				_weapon_bone.position = target.lerp(Vector2(81 + direction * 58, 108 + collapse * 25), retreat)
				_weapon_bone.rotation = -direction * lerpf(PI / 2.0, 0.25, retreat)
		else:
			_weapon_bone.position = Vector2(81 + direction * 67, 86).lerp(Vector2(81 + direction * 28, 77), approach)
			_weapon_bone.rotation = direction * lerpf(1.1, 0.6, approach)
			_weapon_bone.position = _weapon_bone.position.lerp(Vector2(81 + direction * 67, 94), retreat)
			_weapon_bone.rotation = lerpf(_weapon_bone.rotation, direction * 1.1, retreat)
	else:
		_weapon_rig.visible = false
	_update_male_frame(stage, active, collapse, impact)
	_set_male_layers(stage)
	_pose_female_arms(stage, active)


func _pixel_hit(sprite: Sprite2D, point: Vector2) -> bool:
	if not sprite.is_visible_in_tree():
		return false
	var local := sprite.to_local(to_global(point))
	if not sprite.get_rect().has_point(local):
		return false
	if sprite.region_enabled:
		local += sprite.region_rect.position
	var texture := sprite.texture
	var key := texture.get_instance_id()
	if not _images.has(key):
		_images[key] = texture.get_image()
	return _images[key].get_pixel(int(local.x), int(local.y)).a > 0.1


func hit_test(point: Vector2) -> bool:
	# Front furniture occludes seated body; it must never count as a leader hit.
	if _rig.z_index > _desk.z_index:
		for sprite in _body_sprites:
			if _pixel_hit(sprite, point): return true
	for sprite in [_desk, _male_desk_front]:
		if sprite != null and _pixel_hit(sprite, point):
			return false
	for sprite in _props.values():
		if sprite != null and _pixel_hit(sprite, point):
			return false
	# Fingers draw in front of the held cup; the cup itself blocks the face behind it.
	if _pixel_hit(_parts.right_hand, point):
		return true
	if _pixel_hit(_idle_prop, point):
		return false
	for sprite in _body_sprites:
		if _pixel_hit(sprite, point):
			return true
	return false


func solid_test(point: Vector2) -> bool:
	for sprite in _solid_sprites:
		if _pixel_hit(sprite, point):
			return true
	return false


func _draw() -> void:
	if not is_node_ready():
		return
	var stage := int(state.get("stage", 0))
	if not _event.is_empty():
		var contact := 0.17 if _event.get("critical", false) else 0.06
		var t := _elapsed - contact
		if t >= 0.0 and t < 0.23:
			var center := Vector2(81, 48) if _event.get("critical", false) else Vector2(81 + float(_event.get("direction", 1)) * 26, 55)
			if _event.weapon == "gloves" and not _event.get("critical", false):
				center = Vector2(81 + float(_event.direction) * 24, 68 + (25 if stage == 4 else 0))
			var radius := 12.0 + t * 35.0
			for i in range(8):
				var angle := i * TAU / 8
				var ray := Vector2(cos(angle), sin(angle))
				draw_line((center + ray * radius * 0.5).round(), (center + ray * radius).round(), Color("fff0b5"), 3.0, false)
				draw_rect(Rect2((center + ray * (radius + 5)).round(), Vector2(2, 2)), Color("e79777"))
			if t < 0.08:
				draw_rect(Rect2(center - Vector2(3, 3), Vector2(6, 6)), Color("fffbe0"))
