class_name PetSession
extends RefCounted

signal attack_started(event: Dictionary)
signal changed
signal character_recovered(character: String)

const CHARACTERS := ["male", "female"]
const WEAPONS := ["hammer", "gloves"]
const CAP := 36
const RECOVERY_HOLD := 5.0

var selected: String = "male"
var weapon: String = "hammer"

var _states := {}
var _queue: Array[bool] = []
var _remaining := 0.0
var _roll_source: Callable = Callable()


func _init() -> void:
	_reset_states()


func set_roll_source(source: Callable) -> void:
	_roll_source = source


func request_attack(hit: bool = true) -> bool:
	if not hit:
		return false
	if is_busy():
		if _queue.size() >= 2:
			return false
		_queue.append(true)
		changed.emit()
		return true
	_execute_attack()
	return true


func advance(delta: float) -> void:
	if delta <= 0.0:
		return
	_advance_recovery(delta)
	if not is_busy():
		return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= 0.0 and not _queue.is_empty():
		_queue.pop_front()
		_execute_attack()
	else:
		changed.emit()


func select_character(id: String) -> void:
	if id not in CHARACTERS or id == selected:
		return
	selected = id
	cancel_attacks()
	changed.emit()


func select_weapon(id: String) -> void:
	if id not in WEAPONS or id == weapon:
		return
	weapon = id
	changed.emit()


func reset_all() -> void:
	_reset_states()
	cancel_attacks()
	changed.emit()


func reset_character(id: String = "") -> void:
	var character := selected if id == "" else id
	if character not in CHARACTERS:
		return
	_states[character] = _fresh_state()
	if character == selected:
		cancel_attacks()
	changed.emit()


func cancel_attacks() -> void:
	_queue.clear()
	_remaining = 0.0
	changed.emit()


func snapshot(id: String = "") -> Dictionary:
	var character := selected if id == "" else id
	if character not in CHARACTERS:
		character = selected
	var state: Dictionary = _states[character]
	var progress: int = state.progress
	return {
		"progress": progress,
		"stage": _stage_for(progress),
		"bump": state.bump,
		"chin": state.chin,
	}


func is_busy() -> bool:
	return _remaining > 0.0


func queued_count() -> int:
	return _queue.size()


func _reset_states() -> void:
	_states = {
		"male": _fresh_state(),
		"female": _fresh_state(),
	}


func _fresh_state() -> Dictionary:
	return {"progress": 0, "pity": 0, "direction": -1, "bump": 0, "chin": 0, "recover_in": -1.0}


func _advance_recovery(delta: float) -> void:
	for character in CHARACTERS:
		var state: Dictionary = _states[character]
		if float(state.recover_in) < 0.0:
			continue
		state.recover_in = float(state.recover_in) - delta
		if float(state.recover_in) > 0.0:
			continue
		_states[character] = _fresh_state()
		if character == selected:
			_queue.clear()
			_remaining = 0.0
		character_recovered.emit(character)
		changed.emit()


func _execute_attack() -> void:
	var state: Dictionary = _states[selected]
	var was_terminal: bool = state.progress >= CAP
	var critical := false
	if not was_terminal:
		critical = state.pity >= 4 or _roll() < 0.15
		if critical:
			state.pity = 0
		else:
			state.pity += 1
	var direction := 0 if critical else int(state.direction)
	if not critical:
		state.direction = -int(state.direction)
	var old_progress: int = state.progress
	state.progress = mini(CAP, old_progress + (2 if critical else 1))
	var finale: bool = old_progress < CAP and state.progress == CAP
	if finale:
		state.recover_in = 1.2 + RECOVERY_HOLD
	if critical and weapon == "hammer":
		state.bump += 1
	elif critical and weapon == "gloves":
		state.chin += 1
	var duration := 0.25 if was_terminal else (1.2 if finale else (0.7 if critical else 0.35))
	_remaining = duration
	var event := {
		"character": selected,
		"weapon": weapon,
		"critical": critical,
		"direction": direction,
		"progress": state.progress,
		"stage": _stage_for(state.progress),
		"terminal": was_terminal,
		"finale": finale,
		"duration": duration,
	}
	attack_started.emit(event)
	changed.emit()


func _roll() -> float:
	if _roll_source.is_valid():
		return clampf(float(_roll_source.call()), 0.0, 1.0)
	return randf()


func _stage_for(progress: int) -> int:
	if progress >= 36:
		return 4
	if progress >= 27:
		return 3
	if progress >= 18:
		return 2
	if progress >= 9:
		return 1
	return 0
