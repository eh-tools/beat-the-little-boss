extends SceneTree

const Geometry = preload("res://src/desktop_geometry.gd")
const Settings = preload("res://src/settings_window.gd")
const Data = preload("res://src/pet_data.gd")
const Audio = preload("res://src/audio.gd")
const View = preload("res://src/pet_view.gd")
const PetTheme = preload("res://src/pet_theme.gd")
var failures := 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

## Godot's own PopupMenu / FileDialog internals contain scroll areas; only the page's own count matters.
func in_popup(node: Node) -> bool:
	var current := node.get_parent()
	while current != null:
		if current is Popup or current is AcceptDialog: return true
		current = current.get_parent()
	return false

func opaque_bounds(image: Image) -> Rect2i:
	var low := Vector2i(image.get_width(), image.get_height())
	var high := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				low.x = mini(low.x, x)
				low.y = mini(low.y, y)
				high.x = maxi(high.x, x)
				high.y = maxi(high.y, y)
	return Rect2i(low, high - low + Vector2i.ONE)

## True when every mirrored destination column of `right` samples the same pixel as `left`.
func mirrors_about(right: Image, left: Image, axis: int) -> bool:
	for y in right.get_height():
		for x in right.get_width():
			var source_x := axis * 2 - x
			if source_x < 0 or source_x >= left.get_width(): continue
			if right.get_pixel(x, y).to_rgba32() != left.get_pixel(source_x, y).to_rgba32(): return false
	return true

## The opaque pixel pattern relative to its own bounding box: identical for pure translations,
## different once the frame is rotated.
func relative_shape(image: Image, bounds: Rect2i) -> String:
	var points: Array[String] = []
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				points.append("%d,%d" % [x - bounds.position.x, y - bounds.position.y])
	return "|".join(points)

func run() -> void:
	var view := View.new()
	root.add_child(view)
	await process_frame
	check(View.CURSOR_FRAME_SIZE == 72 and View.CURSOR_FRAME_SIZE / 2 == 36, "hover cursor uses the approved 72px canvas around the 36,36 hotspot")
	for step in [[0.0, 0], [0.05, 0], [0.19, 0], [0.2, 1], [0.39, 1], [0.4, 2], [0.6, 3], [0.8, 4], [0.95, 4], [1.0, 0], [1.5, 2], [2.2, 1]]:
		check(view.weapon_cursor_frame_index(step[0]) == step[1], "hover cursor frame %d covers %.2fs" % [step[1], step[0]])
	check(view.weapon_cursor_frame_index(-1.0) == 0, "negative hover time is clamped to the first frame")
	check(View.CURSOR_FRAME_COUNT == 5, "hover cursor loops through five frames")
	check(is_equal_approx(View.CURSOR_FRAME_SECONDS, 0.2) and is_equal_approx(View.CURSOR_FRAME_COUNT * View.CURSOR_FRAME_SECONDS, 1.0), "hover cursor advances every 200ms and loops once a second")
	for weapon in ["hammer", "gloves"]:
		var frames: Array[Texture2D] = []
		var origins := {}
		var shapes := {}
		for index in View.CURSOR_FRAME_COUNT:
			frames.append(view.weapon_cursor_frame(weapon, index))
		check(view.weapon_cursor_frame(weapon, 0) == frames[0], "%s cursor frames are cached" % weapon)
		for index in View.CURSOR_FRAME_COUNT:
			var texture: Texture2D = frames[index]
			check(texture.get_width() == 72 and texture.get_height() == 72, "%s frame %d keeps the 72px canvas" % [weapon, index])
			var image: Image = texture.get_image()
			check(image.get_pixel(0, 0).a == 0.0 and image.get_pixel(71, 0).a == 0.0 and image.get_pixel(0, 71).a == 0.0 and image.get_pixel(71, 71).a == 0.0, "%s frame %d stays transparent outside the art" % [weapon, index])
			var bounds := opaque_bounds(image)
			origins[str(bounds.position)] = true
			shapes[relative_shape(image, bounds)] = true
		for left in View.CURSOR_FRAME_COUNT:
			for right in range(left + 1, View.CURSOR_FRAME_COUNT):
				check(frames[left].get_image().get_data() != frames[right].get_image().get_data(), "%s frames %d and %d are different drawings" % [weapon, left, right])
		check(origins.size() == View.CURSOR_FRAME_COUNT, "%s frames each sit at a different canvas position" % weapon)
		check(shapes.size() == View.CURSOR_FRAME_COUNT, "%s frames each use a different rotated drawing" % weapon)
	var hammer_data: Array[PackedByteArray] = []
	for index in View.CURSOR_FRAME_COUNT:
		hammer_data.append(view.weapon_cursor_frame("hammer", index).get_image().get_data())
	for index in View.CURSOR_FRAME_COUNT:
		check(view.weapon_cursor_frame("gloves", index).get_image().get_data() != hammer_data[index], "gloves frame %d is not the hammer drawing" % index)
	for pair in [[0, 2], [1, 3]]:
		var left: Image = view.weapon_cursor_frame("gloves", pair[0]).get_image()
		var right: Image = view.weapon_cursor_frame("gloves", pair[1]).get_image()
		check(mirrors_about(right, left, 36), "glove frame %d mirrors the left-side frame %d" % [pair[1], pair[0]])
	check(not mirrors_about(view.weapon_cursor_frame("gloves", 4).get_image(), view.weapon_cursor_frame("gloves", 0).get_image(), 36), "the recovery glove frame is its own centred pose")
	for impact in [1, 3]:
		check(opaque_bounds(view.weapon_cursor_frame("gloves", impact).get_image()).has_point(Vector2i(36, 36)), "glove impact frame %d lands on the hotspot" % impact)
	view.queue_free()

	var theme: Theme = PetTheme.build_settings_theme()
	check(theme.default_font == PetTheme.font(), "settings theme uses the bundled pixel font")
	var button_style := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	check(button_style.bg_color == PetTheme.TEAL and button_style.border_color == PetTheme.INK and button_style.get_border_width(SIDE_LEFT) == 2, "settings buttons use the teal pixel fill and 2px ink border")
	check(button_style.shadow_color == PetTheme.INK and button_style.shadow_size == 0 and button_style.shadow_offset == Vector2(3, 3), "settings buttons carry the 3px pixel shadow")
	var input_style := theme.get_stylebox("normal", "LineEdit") as StyleBoxFlat
	check(input_style.bg_color == PetTheme.SURFACE and input_style.get_border_width(SIDE_TOP) == 2, "settings input uses the warm surface with an ink border")
	check(theme.get_color("font_color", "LineEdit") == PetTheme.INK and theme.get_color("font_placeholder_color", "LineEdit") == PetTheme.MUTED, "settings input text uses the palette")
	var option_style := theme.get_stylebox("normal", "OptionButton") as StyleBoxFlat
	check(option_style.bg_color == PetTheme.SURFACE and option_style.get_border_width(SIDE_LEFT) == 2, "settings selectors match the input surface")
	check(theme.get_icon("arrow", "OptionButton").get_width() > 0, "settings selectors carry a pixel arrow")
	var popup_panel := theme.get_stylebox("panel", "PopupMenu") as StyleBoxFlat
	var popup_hover := theme.get_stylebox("hover", "PopupMenu") as StyleBoxFlat
	check(popup_panel.bg_color == PetTheme.CREAM and popup_panel.border_color == PetTheme.INK and popup_hover.bg_color == PetTheme.GOLD, "settings dropdown popup reuses the menu palette")
	var track := theme.get_stylebox("slider", "HSlider") as StyleBoxFlat
	var fill := theme.get_stylebox("grabber_area", "HSlider") as StyleBoxFlat
	check(track.bg_color == PetTheme.FILTER and fill.bg_color == PetTheme.CORAL, "volume slider uses the warm track and coral fill")
	check(theme.get_icon("grabber", "HSlider").get_width() == 12 and theme.get_icon("grabber", "HSlider").get_height() == 12, "volume slider grabber is a 12px square")
	var scroll_track := theme.get_stylebox("scroll", "VScrollBar") as StyleBoxFlat
	check(scroll_track.bg_color == PetTheme.FILTER and scroll_track.get_minimum_size().x == 10, "the settings scrollbar track is 10px of warm colour")
	check((theme.get_stylebox("grabber", "VScrollBar") as StyleBoxFlat).bg_color == PetTheme.CORAL, "the settings scrollbar grabber is coral")
	check(theme.get_icon("increment", "VScrollBar").get_width() <= 10 and theme.get_icon("checked", "CheckButton").get_width() == 14, "settings scrollbar and checkbox icons are pixel sized")

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
	var page_scrolls := editor.find_children("*", "ScrollContainer", true, false).filter(func(node): return not in_popup(node))
	check(page_scrolls.size() == 1, "settings page has exactly one scroll region")
	var scroll_bar: VScrollBar = (editor.find_child("SettingsScroll", true, false) as ScrollContainer).get_v_scroll_bar()
	check(scroll_bar.size.x == 10, "the settings scrollbar renders 10px wide")
	check(editor.lines.find_children("*", "ScrollContainer", true, false).is_empty(), "quote rows do not add a nested scrollbar")
	var header := editor.find_child("HeaderBar", true, false) as PanelContainer
	check(header != null, "settings header bar exists")
	if header != null:
		var header_style := header.get_theme_stylebox("panel") as StyleBoxFlat
		check(header_style.bg_color == PetTheme.INK and header.custom_minimum_size.y == 48, "settings header is an ink 48px bar")
	var title := editor.find_child("HeaderTitle", true, false) as Label
	check(title != null and title.get_theme_color("font_color") == PetTheme.GOLD and title.get_theme_font_size("font_size") == 20, "settings header title is gold 20px")
	var eyebrow := editor.find_child("Eyebrow", true, false) as Label
	check(eyebrow != null and eyebrow.get_theme_font_size("font_size") == 14, "settings eyebrow uses the muted 14px label")
	var headings := editor.find_children("*", "Label", true, false).filter(func(label): return label.text == "让领导换一套说辞。")
	check(headings.size() == 1 and headings[0].get_theme_font_size("font_size") == 24 and headings[0].get_theme_color("font_color") == PetTheme.INK, "settings heading is ink 24px")
	var filter_panel := editor.find_child("FilterPanel", true, false) as PanelContainer
	var filter_style := filter_panel.get_theme_stylebox("panel") as StyleBoxFlat
	check(filter_style.bg_color == PetTheme.FILTER and filter_style.border_color == PetTheme.LINE and filter_style.get_border_width(SIDE_LEFT) == 2, "filters sit on the warm bordered panel")
	var quote_list := editor.find_child("QuoteList", true, false) as PanelContainer
	var list_style := quote_list.get_theme_stylebox("panel") as StyleBoxFlat
	check(list_style.border_color == PetTheme.INK and list_style.get_border_width(SIDE_LEFT) == 2 and editor.lines.get_theme_constant("separation") == 0, "quote list has one ink border and no row gaps")
	for control in [editor.role, editor.category, editor.stage, editor.input]:
		check(control.custom_minimum_size.y >= 38, "settings controls are at least 38px tall")
	var row := editor.lines.get_child(0) as PanelContainer
	check(row.custom_minimum_size.y >= 38, "quote rows are at least 38px tall")
	var row_inner := row.get_child(0) as HBoxContainer
	var tag := row_inner.get_child(0) as PanelContainer
	var tag_style := tag.get_theme_stylebox("panel") as StyleBoxFlat
	check(tag.custom_minimum_size.x == 66 and tag_style.bg_color == PetTheme.CORAL and tag_style.border_color == PetTheme.INK and tag_style.get_border_width(SIDE_RIGHT) == 2, "quote tag is a 66px coral stage label with an ink divider")
	var quote := row_inner.get_child(1) as Button
	check((quote.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == PetTheme.SURFACE and (quote.get_theme_stylebox("pressed") as StyleBoxFlat).bg_color == PetTheme.GOLD, "quote rows use cream normally and gold when selected")
	editor._select_row(editor.filtered_indices[0])
	check(quote.button_pressed and quote.get_theme_color("font_color") == PetTheme.INK, "selecting a row marks it as the gold current row")
	var rule: Variant = editor.find_child("VolumeRule", true, false)
	check(rule != null and rule.get("thickness") == 2 and rule.get("rule_color") == PetTheme.LINE, "volume section starts with a 2px dashed rule")
	if editor.lines.get_child_count() > 1:
		check((editor.lines.get_child(editor.lines.get_child_count() - 1).get_theme_stylebox("panel") as StyleBoxFlat).get_border_width(SIDE_BOTTOM) == 0, "the last quote row leaves the list border clean")
	check((editor.volume.custom_minimum_size.y >= 12), "volume slider keeps the pixel track height")
	var save_button: Button
	var delete_button: Button
	for button in editor.find_children("*", "Button", true, false):
		if button.text == "保存设置": save_button = button
		if button.text == "删除": delete_button = button
	check(save_button != null and (save_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == PetTheme.TEAL, "save button uses the teal action style")
	check(delete_button != null and (delete_button.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == PetTheme.CORAL and (delete_button.get_theme_stylebox("normal") as StyleBoxFlat).shadow_offset == Vector2(3, 3), "delete button uses the coral destructive style")
	var background := editor.find_child("SettingsBackground", true, false) as ColorRect
	check(background != null and background.color == PetTheme.CREAM, "settings page sits on the cream surface")
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
