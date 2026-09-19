class_name BubbleClock
extends RefCounted

var text: String = ""
var visible: bool = false

var _idle_remaining := 0.0
var _visible_remaining := 0.0
var _refresh_remaining := 0.0
var _hit_active := false
var _roll_source: Callable = Callable()


func _init() -> void:
	_idle_remaining = _idle_delay()


func set_roll_source(source: Callable) -> void:
	_roll_source = source
	_idle_remaining = _idle_delay()


func advance(delta: float) -> bool:
	if delta <= 0.0:
		return false
	_refresh_remaining = maxf(0.0, _refresh_remaining - delta)
	if visible:
		_visible_remaining = maxf(0.0, _visible_remaining - delta)
		if _visible_remaining <= 0.0:
			_clear_bubble()
	_idle_remaining -= delta
	if _idle_remaining <= 0.0:
		_idle_remaining = _idle_delay()
		return true
	return false


func show_hit(value: String) -> void:
	if _refresh_remaining > 0.0:
		return
	text = value
	visible = value != ""
	_hit_active = visible
	_visible_remaining = _display_duration() if visible else 0.0
	_refresh_remaining = 0.12


func show_idle(value: String) -> void:
	if _hit_active and visible:
		return
	text = value
	visible = value != ""
	_hit_active = false
	_visible_remaining = _display_duration() if visible else 0.0


func clear() -> void:
	_clear_bubble()
	_refresh_remaining = 0.0


func _clear_bubble() -> void:
	text = ""
	visible = false
	_visible_remaining = 0.0
	_hit_active = false


func _idle_delay() -> float:
	return 10.0 + _roll() * 5.0


func _display_duration() -> float:
	return 2.0 + _roll()


func _roll() -> float:
	if _roll_source.is_valid():
		return clampf(float(_roll_source.call()), 0.0, 1.0)
	return randf()
