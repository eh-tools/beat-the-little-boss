extends Node

const Session = preload("res://src/pet_session.gd")
const Data = preload("res://src/pet_data.gd")
const Clock = preload("res://src/bubble_clock.gd")
const View = preload("res://src/pet_view.gd")
const Settings = preload("res://src/settings_window.gd")
const Sound = preload("res://src/audio.gd")
const Geometry = preload("res://src/desktop_geometry.gd")
const PetTheme = preload("res://src/pet_theme.gd")
const BODY_MARGIN := Vector2(16, 16)
const WINDOW_SIZE := Vector2(192, 212)
# The OS pointer stays on this fixed hotspot (the frame canvas centre) so the weapon art
# animates around it instead of dragging the pointer along.
const CURSOR_HOTSPOT := Vector2(36, 36)

var session = Session.new()
var data = Data.new()
var bubble_clock = Clock.new()
var pet: Node2D
var sounds: Node
var menu: PopupMenu
var scale_menu: PopupMenu
var settings: Window
var bubble: Window
var bubble_label: Label
var critical_label: Label
var notice: AcceptDialog
var root_window: Window
var config_path := ""
var zoom := 1.0
var pressed := false
var dragging := false
var press_screen := Vector2i.ZERO
var press_window := Vector2i.ZERO
var press_hit := false
var cursor_on := false
var cursor_frame := -1
var cursor_elapsed := 0.0
var critical_left := 0.0
var layout_check := 0.0
var known_screens: Array[Rect2i] = []
var native_error_shown := false
var startup_position := Vector2i.ZERO

func _ready() -> void:
	Engine.max_fps = 60
	root_window = get_window()
	root_window.transparent_bg = true
	root_window.borderless = true
	root_window.transparent = true
	root_window.unresizable = true
	root_window.gui_embed_subwindows = false
	root_window.close_requested.connect(_quit)
	config_path = _config_location()
	var loaded: bool = data.load_from(config_path)
	session.selected = data.preferences.character
	session.weapon = data.preferences.weapon
	pet = View.new()
	add_child(pet)
	pet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pet.set_character(session.selected, session.snapshot())
	sounds = Sound.new()
	add_child(sounds)
	_create_bubble()
	_create_menu()
	_create_notice()
	settings = Settings.new()
	settings.data = data
	settings.save_requested.connect(_save_preferences)
	add_child(settings)
	session.attack_started.connect(_attack_started)
	session.character_recovered.connect(_character_recovered)
	_apply_preferences(false)
	known_screens = Geometry.work_areas()
	var startup_size := Vector2i(WINDOW_SIZE * zoom)
	var saved = data.preferences.position
	if saved is Array and saved.size() == 2:
		startup_position = Geometry.fit_position(Vector2i(int(saved[0]), int(saved[1])), startup_size, known_screens)
	else:
		var work := DisplayServer.screen_get_usable_rect(DisplayServer.get_primary_screen())
		startup_position = work.end - startup_size - Vector2i(32, 24)
	if not loaded:
		_show_error(data.last_error)
	_update_bubble()
	_show_when_ready.call_deferred()

func _show_when_ready() -> void:
	await get_tree().process_frame
	root_window.unfocusable = false
	root_window.position = startup_position
	root_window.size = Vector2i(WINDOW_SIZE * zoom)

func _config_location() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--config-path="):
			return argument.trim_prefix("--config-path=")
	if OS.has_feature("editor"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://local-data"))
		return ProjectSettings.globalize_path("res://local-data/preferences.json")
	return OS.get_executable_path().get_base_dir().path_join("preferences.json")

func _process(delta: float) -> void:
	if not is_instance_valid(root_window): return
	session.advance(delta)
	var idle_due: bool = bubble_clock.advance(delta)
	if idle_due and not session.is_busy():
		var state: Dictionary = session.snapshot()
		bubble_clock.show_idle(data.pick_quote(session.selected, "plead" if state.stage == 4 else "idle", state.stage))
	critical_left = maxf(0.0, critical_left - delta)
	critical_label.visible = critical_left > 0.0
	var screen_mouse := DisplayServer.mouse_get_position()
	_update_drag(screen_mouse)
	var body_mouse := (Vector2(screen_mouse - root_window.position) / zoom) - BODY_MARGIN
	var solid: bool = pet.solid_test(body_mouse)
	var active := root_window.mode != Window.MODE_MINIMIZED
	root_window.mouse_passthrough = not solid and not pressed
	_set_native_passthrough(root_window, root_window.mouse_passthrough)
	var hover: bool = solid and pet.hit_test(body_mouse) and not dragging and active and not menu.visible and not settings.visible
	if hover and cursor_on:
		cursor_elapsed += delta
	pet.set_hovered(hover)
	_set_cursor(hover)
	_update_bubble()
	layout_check += delta
	if layout_check >= 1.0:
		layout_check = 0.0
		var current := Geometry.work_areas()
		if current != known_screens:
			known_screens = current
			root_window.position = Geometry.fit_position(root_window.position, root_window.size, known_screens)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and pressed:
		_update_drag(DisplayServer.mouse_get_position())
		return
	if event is InputEventKey and event.pressed and not event.echo and root_window.has_focus():
		if event.keycode == KEY_1: _choose_weapon("hammer")
		if event.keycode == KEY_2: _choose_weapon("gloves")
	if not event is InputEventMouseButton: return
	var point: Vector2 = (event.position / zoom) - BODY_MARGIN
	if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		if not pressed and not dragging and not menu.visible and not settings.visible and pet.hit_test(point):
			_reset_selected()
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if pet.solid_test(point): _open_menu()
	if event.button_index != MOUSE_BUTTON_LEFT: return
	if event.pressed:
		if not pet.solid_test(point): return
		pressed = true
		dragging = false
		press_hit = pet.hit_test(point)
		press_screen = root_window.position + Vector2i(event.position)
		press_window = root_window.position
	else:
		if not pressed: return
		_update_drag(DisplayServer.mouse_get_position())
		if dragging:
			_store_position()
		else:
			session.request_attack(press_hit and pet.hit_test(point))
		pressed = false
		dragging = false

func _update_drag(screen_mouse: Vector2i) -> void:
	if not pressed: return
	if not dragging and screen_mouse.distance_to(press_screen) > 6.0:
		dragging = true
		_set_cursor(false)
	if dragging:
		root_window.position = Geometry.fit_position(press_window + screen_mouse - press_screen, root_window.size, known_screens)

func _set_cursor(on: bool) -> void:
	if not on:
		if not cursor_on:
			return
		cursor_on = false
		cursor_frame = -1
		cursor_elapsed = 0.0
		Input.set_custom_mouse_cursor(null)
		return
	if not cursor_on:
		cursor_on = true
		cursor_elapsed = 0.0
		cursor_frame = -1
	var frame_index: int = pet.weapon_cursor_frame_index(cursor_elapsed)
	if frame_index == cursor_frame:
		return
	cursor_frame = frame_index
	var texture: Texture2D = pet.weapon_cursor_frame(session.weapon, frame_index)
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, CURSOR_HOTSPOT)

func _attack_started(event: Dictionary) -> void:
	pet.play_attack(event)
	sounds.play_hit(event)
	bubble_clock.show_hit(data.pick_quote(event.character, "plead" if event.stage == 4 else "hit", event.stage))
	if event.critical and not event.terminal:
		critical_left = 0.65
	_update_bubble()

func _character_recovered(character: String) -> void:
	if character != session.selected:
		return
	pet.set_character(character, session.snapshot(character))
	critical_left = 0.0
	bubble_clock.show_hit(data.pick_quote(character, "idle", 0))
	_update_bubble()

func _create_bubble() -> void:
	bubble = Window.new()
	bubble.title = "Beat the Little Boss"
	bubble.borderless = true
	bubble.transparent = true
	bubble.transparent_bg = true
	bubble.unfocusable = true
	bubble.mouse_passthrough = true
	bubble.transient = true
	bubble.unresizable = true
	bubble.visible = false
	add_child(bubble)
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fff4d9")
	style.border_color = Color("303247")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.18)
	style.shadow_size = 2
	panel.add_theme_stylebox_override("panel", style)
	bubble.add_child(panel)
	bubble_label = Label.new()
	bubble_label.position = Vector2(10, 6)
	bubble_label.size = Vector2(176, 44)
	bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.add_theme_color_override("font_color", Color("303247"))
	bubble_label.add_theme_font_size_override("font_size", 14)
	bubble_label.add_theme_font_override("font", _chinese_font())
	bubble.add_child(bubble_label)
	critical_label = Label.new()
	critical_label.text = "暴击！"
	critical_label.add_theme_font_override("font", _chinese_font())
	critical_label.add_theme_font_size_override("font_size", 18)
	critical_label.add_theme_color_override("font_color", Color("ffe491"))
	critical_label.add_theme_color_override("font_outline_color", Color("553447"))
	critical_label.add_theme_constant_override("outline_size", 6)
	critical_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	critical_label.visible = false
	add_child(critical_label)

func _update_bubble() -> void:
	var show_it: bool = bubble_clock.visible and root_window.mode != Window.MODE_MINIMIZED and not settings.visible and not menu.visible
	bubble.visible = show_it
	if not show_it: return
	_set_native_passthrough(bubble, true)
	bubble_label.text = bubble_clock.text
	# Anchor above the actual sprite head, not the transparent window boundary.
	var head_anchor_y := int((BODY_MARGIN.y + 25.0) * zoom)
	var target := root_window.position + Vector2i((root_window.size.x - bubble.size.x) / 2, head_anchor_y - bubble.size.y)
	bubble.position = Geometry.fit_position(target, bubble.size, known_screens)

func _set_native_passthrough(window: Window, enabled: bool) -> void:
	if DisplayServer.get_name() == "headless": return
	var handle := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, window.get_window_id())
	if not WindowsMousePassthrough.set_passthrough(handle, enabled) and not native_error_shown:
		native_error_shown = true
		_show_error("Windows 鼠标穿透设置失败，请重新启动桌宠。")

static func _chinese_font() -> FontFile:
	return PetTheme.font()

func _create_menu() -> void:
	menu = PopupMenu.new()
	_style_popup(menu)
	add_child(menu)
	menu.id_pressed.connect(_menu_action)
	scale_menu = PopupMenu.new()
	_style_popup(scale_menu)
	scale_menu.id_pressed.connect(_menu_action)
	menu.add_separator("角色")
	menu.add_radio_check_item("男领导 · 甩锅担当", 10)
	menu.add_radio_check_item("女领导 · 画饼专家", 11)
	menu.add_separator("工具")
	menu.add_radio_check_item("充气大锤    1", 20)
	menu.add_radio_check_item("双拳套        2", 21)
	menu.add_separator("显示")
	menu.add_submenu_node_item("放大比例", scale_menu)
	menu.add_check_item("总在最前", 40)
	menu.add_check_item("播放音效", 41)
	menu.add_separator("桌宠")
	menu.add_item("语录与音量设置…", 50)
	menu.add_item("恢复当前领导（中键）", 61)
	menu.add_item("全部恢复正常", 60)
	menu.add_item("隐藏到任务栏", 70)
	menu.add_item("退出", 80)
	for option in [30, 31, 32]:
		scale_menu.add_radio_check_item(["原始大小 · 1 倍", "放大 · 1.5 倍", "放大 · 2 倍"][option - 30], option)

func _style_popup(popup: PopupMenu) -> void:
	popup.add_theme_font_override("font", _chinese_font())
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", PetTheme.INK)
	popup.add_theme_color_override("font_hover_color", PetTheme.INK)
	popup.add_theme_color_override("font_separator_color", PetTheme.MUTED)
	popup.add_theme_color_override("font_disabled_color", Color("9d8e88"))
	popup.add_theme_constant_override("item_start_padding", 14)
	popup.add_theme_constant_override("item_end_padding", 14)
	popup.add_theme_constant_override("vertical_separation", 5)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PetTheme.CREAM
	panel_style.border_color = PetTheme.INK
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	panel_style.shadow_color = Color(0, 0, 0, 0.18)
	panel_style.shadow_size = 2
	popup.add_theme_stylebox_override("panel", panel_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = PetTheme.GOLD
	hover_style.border_color = PetTheme.CORAL
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(2)
	popup.add_theme_stylebox_override("hover", hover_style)

func _open_menu() -> void:
	pressed = false
	dragging = false
	_set_cursor(false)
	for pair in [[10, session.selected == "male"], [11, session.selected == "female"], [20, session.weapon == "hammer"], [21, session.weapon == "gloves"], [40, data.preferences.topmost], [41, data.preferences.sound]]:
		menu.set_item_checked(menu.get_item_index(pair[0]), pair[1])
	for pair in [[30, zoom == 1.0], [31, zoom == 1.5], [32, zoom == 2.0]]:
		scale_menu.set_item_checked(scale_menu.get_item_index(pair[0]), pair[1])
	menu.position = DisplayServer.mouse_get_position()
	menu.popup()

func _menu_action(id: int) -> void:
	match id:
		10, 11:
			session.select_character("male" if id == 10 else "female")
			data.preferences.character = session.selected
			pet.set_character(session.selected, session.snapshot())
			bubble_clock.clear()
			critical_left = 0.0
		20, 21:
			_choose_weapon("hammer" if id == 20 else "gloves")
			return
		30, 31, 32: data.preferences.scale = [1.0, 1.5, 2.0][id - 30]
		40: data.preferences.topmost = not data.preferences.topmost
		41: data.preferences.sound = not data.preferences.sound
		50:
			settings.open_editor()
			return
		60: _reset_all()
		61: _reset_selected()
		70:
			bubble.hide()
			root_window.mode = Window.MODE_MINIMIZED
			return
		80:
			_quit()
			return
	_apply_preferences()
	_save_preferences()

func _reset_selected() -> void:
	session.reset_character()
	_refresh_after_reset()

func _reset_all() -> void:
	session.reset_all()
	_refresh_after_reset()

func _refresh_after_reset() -> void:
	pet.set_character(session.selected, session.snapshot())
	bubble_clock.clear()
	critical_left = 0.0

func _choose_weapon(value: String) -> void:
	session.select_weapon(value)
	data.preferences.weapon = value
	_set_cursor(false)
	_save_preferences()

func _apply_preferences(resize_window: bool = true) -> void:
	zoom = float(data.preferences.scale)
	if resize_window:
		var old_size := root_window.size
		root_window.size = Vector2i(WINDOW_SIZE * zoom)
		root_window.position += Vector2i((old_size.x - root_window.size.x) / 2, old_size.y - root_window.size.y)
		root_window.position = Geometry.fit_position(root_window.position, root_window.size, Geometry.work_areas())
	pet.position = BODY_MARGIN * zoom
	pet.scale = Vector2.ONE * zoom
	critical_label.position = Vector2(110, 16) * zoom
	critical_label.scale = Vector2.ONE * zoom
	bubble.size = Vector2i(Vector2(196, 56) * zoom)
	bubble.content_scale_size = Vector2i(196, 56)
	bubble.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.always_on_top = data.preferences.topmost
	# The bubble is an owned (transient) window, so Windows keeps it above the main window
	# and moves it with the main window's z-order. Requesting its own topmost flag is
	# rejected by the platform, and the rejected flag then makes the later hide path fail
	# with "Windows with the 'on top' can't become transient". It must therefore inherit
	# topmost from the owner instead of carrying the flag itself.
	sounds.enabled = data.preferences.sound
	sounds.volume = float(data.preferences.volume)

func _store_position() -> void:
	data.preferences.position = [root_window.position.x, root_window.position.y]
	_save_preferences()

func _save_preferences(recover_defaults: bool = false) -> void:
	_apply_preferences()
	data.preferences.position = [root_window.position.x, root_window.position.y]
	if recover_defaults and not data.recover_corrupt(config_path):
		_show_error(data.last_error)
		return
	if not data.save_to(config_path):
		_show_error(data.last_error)

func _create_notice() -> void:
	notice = AcceptDialog.new()
	notice.title = "桌宠 · 本地设置"
	notice.add_theme_font_override("font", _chinese_font())
	notice.add_theme_font_size_override("font_size", 16)
	notice.add_theme_color_override("font_color", PetTheme.INK)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PetTheme.CREAM
	panel_style.border_color = PetTheme.INK
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	notice.add_theme_stylebox_override("panel", panel_style)
	notice.min_size = Vector2i(420, 160)
	add_child(notice)
	var dialog_label := notice.get_label()
	dialog_label.add_theme_color_override("font_color", PetTheme.CORAL)

func _show_error(message: String) -> void:
	notice.dialog_text = message
	notice.popup_centered()

func _quit() -> void:
	session.cancel_attacks()
	data.preferences.position = [root_window.position.x, root_window.position.y]
	if not data.save_to(config_path):
		_show_error(data.last_error + "\n设置未保存。关闭此提示后可再次退出；原配置会保留。")
		# Closing the application must remain possible even in a read-only directory.
		notice.confirmed.connect(func(): get_tree().quit(), CONNECT_ONE_SHOT)
		return
	get_tree().quit()
