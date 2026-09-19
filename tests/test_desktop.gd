extends SceneTree

const Geometry = preload("res://src/desktop_geometry.gd")
const Settings = preload("res://src/settings_window.gd")
const Data = preload("res://src/pet_data.gd")
const Audio = preload("res://src/audio.gd")
const View = preload("res://src/pet_view.gd")
var failures := 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

func run() -> void:
	var view := View.new()
	root.add_child(view)
	await process_frame
	check(view.weapon_cursor_frame_index(0.0) == 0 and view.weapon_cursor_frame_index(0.12) == 1 and view.weapon_cursor_frame_index(0.24) == 2 and view.weapon_cursor_frame_index(0.36) == 1, "hover cursor follows the four-step pixel animation")
	var cursor_texture: Texture2D = view.weapon_cursor_frame("hammer", 2)
	check(cursor_texture.get_width() == 56 and cursor_texture.get_height() == 56, "hover cursor frames keep a centered 56px canvas")
	view.queue_free()
	var screens: Array[Rect2i] = [Rect2i(0, 0, 1920, 1040), Rect2i(-1280, -200, 1280, 1024)]
	check(Geometry.fit_position(Vector2i(-1000, 100), Vector2i(192, 212), screens) == Vector2i(-1000, 100), "secondary monitor negative origin is retained")
	check(Geometry.fit_position(Vector2i(3000, 3000), Vector2i(192, 212), screens) == Vector2i(1728, 828), "disconnected monitor returns to visible work area")
	check(Geometry.fit_position(Vector2i(-1300, -250), Vector2i(384, 424), screens) == Vector2i(-1280, -200), "scaled window clamps to left monitor")
	var editor := Settings.new()
	editor.data = Data.new()
	root.add_child(editor)
	editor.open_editor()
	await process_frame
	await process_frame
	check(editor.find_child("SettingsScroll", true, false) != null, "settings page has one outer scroll container")
	check(editor.lines.find_children("*", "ScrollContainer", true, false).is_empty(), "quote rows do not add a nested scrollbar")
	var headings := editor.find_children("*", "Label", true, false).filter(func(label): return label.text == "让领导换一套说辞。")
	check(headings.size() == 1 and headings[0].get_theme_font_size("font_size") == 24, "settings heading is 24px")
	for button in editor.find_children("*", "Button", true, false):
		if button.text == "保存设置":
			check(button.get_global_rect().size.y > 0, "save button remains in the settings page")
	var count: int = editor.data.quotes.size()
	editor.input.text = "准时下班"
	editor._add_row()
	check(editor.draft.size() == count + 1 and editor.data.quotes.size() == count, "adding a draft does not change active quotes")
	editor.input.text = "字".repeat(25)
	editor._add_row()
	check(editor.draft.size() == count + 1, "editor visibly rejects overlong draft")
	check(not editor.message.text.is_empty(), "validation message is visible")
	editor._select_row(editor.filtered_indices[-1])
	editor.input.text = "这次真不加班"
	editor._update_row()
	check(editor.draft[-1].text == "这次真不加班", "editing selected row changes draft")
	editor._select_row(editor.filtered_indices[-1])
	editor._delete_row()
	check(editor.draft.size() == count, "deleting selected row changes draft")
	editor._defaults()
	check(editor.draft == Data.default_quotes(), "defaults restore both quote libraries")
	editor.queue_free()
	var audio := Audio.new()
	root.add_child(audio)
	check(audio.sounds.size() == 4, "all four effects generated")
	check(audio.sounds.hammer.data != audio.sounds.gloves.data, "weapons have distinct audio")
	audio.queue_free()
	await process_frame
	if failures == 0: print("desktop tests passed")
	quit(failures)
