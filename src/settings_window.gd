extends Window
## A draft editor: changing rows never mutates live quotes until Save succeeds.
## The whole page lives in one scroll region; the approved pixel theme comes from PetTheme.

const PetTheme = preload("res://src/pet_theme.gd")

signal save_requested(recover_defaults: bool)

var data: RefCounted
var draft: Array = []
var role: OptionButton
var category: OptionButton
var stage: OptionButton
var lines: VBoxContainer
var input: LineEdit
var message: Label
var volume: HSlider
var sound: CheckButton
var filtered_indices: Array[int] = []
var selected_draft_index := -1
var file_dialog: FileDialog
var importing := true
var defaults_requested := false

func _init() -> void:
	# Window 默认 visible = true。必须赶在入树之前隐藏: 若拖到 _ready() 再置 false,
	# main.gd 的 add_child() 入树那一刻 Godot 就已经创建并在屏幕左上角显示了一个
	# 620x660 的原生窗口, 随后才被销毁。DWM 只要合成到那几毫秒, 启动时就会闪过一帧
	# 黑/白方块(内容未绘制时是白的, 已绘制时是界面的深色底)。
	visible = false

func _ready() -> void:
	title = "语录与音量设置 · Beat the Little Boss"
	size = Vector2i(620, 660)
	min_size = Vector2i(570, 610)
	transient = true
	unresizable = false
	close_requested.connect(hide)
	theme = PetTheme.build_settings_theme()
	var background := ColorRect.new()
	background.name = "SettingsBackground"
	background.color = PetTheme.CREAM
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll"
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var page := VBoxContainer.new()
	page.name = "SettingsPage"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 0)
	scroll.add_child(page)
	page.add_child(_header())
	var body := MarginContainer.new()
	body.name = "SettingsBody"
	body.add_theme_constant_override("margin_left", 24)
	body.add_theme_constant_override("margin_right", 24)
	body.add_theme_constant_override("margin_top", 20)
	body.add_theme_constant_override("margin_bottom", 18)
	page.add_child(body)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	body.add_child(column)
	column.add_child(_label("Eyebrow", "QUOTE WORKSHOP", 14, PetTheme.MUTED))
	column.add_child(_label("Heading", "让领导换一套说辞。", 24, PetTheme.INK))
	column.add_child(_label("Description", "筛选、编辑、音量和保存都在一个滚动区域内。", 16, PetTheme.INK))
	var filters := PanelContainer.new()
	filters.name = "FilterPanel"
	var filter_style := PetTheme.flat_box(PetTheme.FILTER, PetTheme.LINE, 2)
	filter_style.content_margin_left = 9
	filter_style.content_margin_right = 9
	filter_style.content_margin_top = 9
	filter_style.content_margin_bottom = 9
	filters.add_theme_stylebox_override("panel", filter_style)
	column.add_child(filters)
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 9)
	filters.add_child(filter_row)
	role = _option(["男领导", "女领导"], filter_row)
	category = _option(["待机", "受击", "求饶"], filter_row)
	role.item_selected.connect(func(_i): _refresh_list())
	category.item_selected.connect(func(_i): _refresh_list())
	var quote_list := PanelContainer.new()
	quote_list.name = "QuoteList"
	quote_list.add_theme_stylebox_override("panel", PetTheme.flat_box(PetTheme.CREAM, PetTheme.INK, 2))
	column.add_child(quote_list)
	lines = VBoxContainer.new()
	lines.name = "QuoteRows"
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.add_theme_constant_override("separation", 0)
	quote_list.add_child(lines)
	column.add_child(_label("EntryLabel", "语录内容 · 最多 24 字，气泡自动分为两行", 16, PetTheme.INK))
	input = LineEdit.new()
	input.placeholder_text = "例如：今天准点下班，我说的！"
	input.custom_minimum_size.y = PetTheme.CONTROL_HEIGHT
	column.add_child(input)
	var actions := HBoxContainer.new()
	actions.name = "StageActions"
	actions.add_theme_constant_override("separation", 10)
	column.add_child(actions)
	stage = _option(["所有阶段", "正常", "轻微受伤", "明显受伤", "重伤", "求饶终态"], actions)
	_button("新增", actions, _add_row)
	_button("更新选中", actions, _update_row)
	_button("删除", actions, _delete_row, PetTheme.CORAL)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 40
	message.add_theme_font_size_override("font_size", 16)
	message.add_theme_color_override("font_color", PetTheme.MUTED)
	column.add_child(message)
	var volume_section := VBoxContainer.new()
	volume_section.name = "VolumeSection"
	volume_section.add_theme_constant_override("separation", 8)
	column.add_child(volume_section)
	volume_section.add_child(PetTheme.dashes())
	var audio_row := HBoxContainer.new()
	audio_row.add_theme_constant_override("separation", 14)
	volume_section.add_child(audio_row)
	sound = CheckButton.new()
	sound.text = "音效"
	sound.custom_minimum_size.y = PetTheme.CONTROL_HEIGHT
	audio_row.add_child(sound)
	volume = HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.custom_minimum_size.y = 24
	audio_row.add_child(volume)
	var volume_label := Label.new()
	volume_label.custom_minimum_size.x = 50
	volume_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	volume_label.add_theme_color_override("font_color", PetTheme.INK)
	audio_row.add_child(volume_label)
	volume.value_changed.connect(func(value): volume_label.text = "%d%%" % value)
	var files := HBoxContainer.new()
	files.name = "FileActions"
	files.add_theme_constant_override("separation", 10)
	column.add_child(files)
	_button("导入文本…", files, func(): _choose_file(true))
	_button("导出文本…", files, func(): _choose_file(false))
	_button("恢复默认语录", files, _defaults)
	var footer := HBoxContainer.new()
	footer.name = "FooterActions"
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	column.add_child(footer)
	_button("关闭", footer, hide)
	_button("保存设置", footer, _save)
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json,*.txt ; 语录文本 (JSON)"])
	file_dialog.size = Vector2i(680, 460)
	file_dialog.file_selected.connect(_file_selected)
	add_child(file_dialog)

func open_editor() -> void:
	defaults_requested = false
	draft = data.quotes.duplicate(true)
	sound.button_pressed = data.preferences.sound
	volume.value = float(data.preferences.volume) * 100.0
	message.text = "选中条目后可修改或删除；空分类会使用内置语录。"
	_refresh_list()
	popup_centered()

func _header() -> PanelContainer:
	# The approved v3 composition opens with a fixed 48px ink bar carrying gold 20px text.
	var bar := PanelContainer.new()
	bar.name = "HeaderBar"
	bar.custom_minimum_size.y = 48
	bar.add_theme_stylebox_override("panel", PetTheme.flat_box(PetTheme.INK, PetTheme.INK, 2))
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 16)
	padding.add_theme_constant_override("margin_right", 16)
	bar.add_child(padding)
	var title := Label.new()
	title.name = "HeaderTitle"
	title.text = "语录与音量设置"
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", PetTheme.GOLD)
	padding.add_child(title)
	return bar

func _label(node_name: String, text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _option(items: Array, parent: Node) -> OptionButton:
	var control := OptionButton.new()
	for item in items: control.add_item(item)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.custom_minimum_size.y = PetTheme.CONTROL_HEIGHT
	parent.add_child(control)
	return control

func _button(text_value: String, parent: Node, action: Callable, background := PetTheme.TEAL) -> Button:
	# Every action button keeps the approved 2px ink border and 3px pixel shadow.
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = PetTheme.CONTROL_HEIGHT
	button.add_theme_stylebox_override("normal", PetTheme.action_box(background))
	button.add_theme_stylebox_override("hover", PetTheme.action_box(PetTheme.GOLD))
	button.add_theme_stylebox_override("pressed", PetTheme.action_box(PetTheme.CORAL))
	button.add_theme_stylebox_override("disabled", PetTheme.action_box(PetTheme.FILTER))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _refresh_list() -> void:
	for child in lines.get_children():
		child.free()
	filtered_indices.clear()
	selected_draft_index = -1
	input.text = ""
	stage.selected = 0
	stage.disabled = category.selected == 2
	for i in draft.size():
		var row: Dictionary = draft[i]
		if row.character != _role() or row.category != _category(): continue
		filtered_indices.append(i)
		var tag_text: String = "通用" if int(row.stage) == -1 else ["正常", "轻伤", "明显", "重伤", "终态"][int(row.stage)]
		var row_control := PanelContainer.new()
		row_control.custom_minimum_size.y = PetTheme.CONTROL_HEIGHT
		row_control.set_meta("draft_index", i)
		row_control.add_theme_stylebox_override("panel", PetTheme.row_box())
		var row_inner := HBoxContainer.new()
		row_inner.add_theme_constant_override("separation", 0)
		row_control.add_child(row_inner)
		var tag := PanelContainer.new()
		tag.custom_minimum_size = Vector2(66, PetTheme.CONTROL_HEIGHT)
		var tag_style := PetTheme.flat_box(PetTheme.CORAL)
		tag_style.border_color = PetTheme.INK
		tag_style.border_width_right = 2
		tag.add_theme_stylebox_override("panel", tag_style)
		row_inner.add_child(tag)
		var tag_label := Label.new()
		tag_label.text = tag_text
		tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag_label.add_theme_font_size_override("font_size", 14)
		tag_label.add_theme_color_override("font_color", PetTheme.INK)
		tag.add_child(tag_label)
		var quote := Button.new()
		quote.text = row.text
		quote.alignment = HORIZONTAL_ALIGNMENT_LEFT
		quote.custom_minimum_size.y = PetTheme.CONTROL_HEIGHT
		quote.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quote.toggle_mode = true
		quote.add_theme_color_override("font_color", PetTheme.INK)
		quote.add_theme_color_override("font_hover_color", PetTheme.INK)
		quote.add_theme_color_override("font_pressed_color", PetTheme.INK)
		quote.add_theme_stylebox_override("normal", PetTheme.flat_box(PetTheme.SURFACE))
		quote.add_theme_stylebox_override("hover", PetTheme.flat_box(PetTheme.GOLD))
		quote.add_theme_stylebox_override("pressed", PetTheme.flat_box(PetTheme.GOLD))
		quote.add_theme_stylebox_override("focus", PetTheme.clear_box())
		quote.pressed.connect(_select_row.bind(i))
		row_inner.add_child(quote)
		lines.add_child(row_control)

func _select_row(draft_index: int) -> void:
	selected_draft_index = draft_index
	var row: Dictionary = draft[draft_index]
	input.text = row.text
	stage.selected = int(row.stage) + 1
	_apply_row_selection()

## The selected draft row is the only gold row in the list. Each row carries its own
## absolute draft index, so highlighting never depends on the current filter order.
func _apply_row_selection() -> void:
	for row_control in lines.get_children():
		var quote := row_control.get_child(0).get_child(1) as Button
		quote.button_pressed = int(row_control.get_meta("draft_index", -1)) == selected_draft_index

func _role() -> String:
	return "male" if role.selected == 0 else "female"

func _category() -> String:
	return ["idle", "hit", "plead"][category.selected]

func _entry() -> Dictionary:
	return {"character": _role(), "category": _category(), "stage": 4 if category.selected == 2 else stage.selected - 1, "text": input.text.strip_edges()}

func _validate_draft(candidate: Array) -> bool:
	# Validate against a separate instance so errors cannot mutate the active library.
	var validator = data.get_script().new()
	if not validator.replace_quotes(candidate):
		message.text = validator.last_error
		return false
	return true

func _add_row() -> void:
	var candidate := draft.duplicate(true)
	candidate.append(_entry())
	if not _validate_draft(candidate): return
	draft = candidate
	_refresh_list()
	message.text = "已加入草稿。点击「保存设置」后生效。"

func _update_row() -> void:
	if selected_draft_index < 0:
		message.text = "请先选中要修改的语录。"
		return
	var candidate := draft.duplicate(true)
	candidate[selected_draft_index] = _entry()
	if not _validate_draft(candidate): return
	draft = candidate
	_refresh_list()
	message.text = "已更新草稿。点击「保存设置」后生效。"

func _delete_row() -> void:
	if selected_draft_index < 0:
		message.text = "请先选中要删除的语录。"
		return
	draft.remove_at(selected_draft_index)
	_refresh_list()
	message.text = "已从草稿删除。空分类自动使用内置语录。"

func _defaults() -> void:
	defaults_requested = true
	draft = data.default_quotes().duplicate(true)
	_refresh_list()
	message.text = "草稿已恢复两位领导的默认语录。保存后生效。"

func _save() -> void:
	if not data.replace_quotes(draft):
		message.text = data.last_error
		return
	data.preferences.sound = sound.button_pressed
	data.preferences.volume = volume.value / 100.0
	save_requested.emit(defaults_requested)
	message.text = "已保存到本机。" if data.last_error.is_empty() else "保存失败：" + data.last_error

func _choose_file(is_import: bool) -> void:
	importing = is_import
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE if importing else FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.title = "导入语录文本" if importing else "导出语录文本"
	if not importing: file_dialog.current_file = "桌宠语录.json"
	file_dialog.popup_centered()

func _file_selected(path: String) -> void:
	var temporary = data.get_script().new()
	if importing:
		if not temporary.import_quotes(path):
			message.text = temporary.last_error
			return
		draft = temporary.quotes.duplicate(true)
		_refresh_list()
		message.text = "导入成功，已载入草稿。保存后生效。"
	else:
		if not temporary.replace_quotes(draft) or not temporary.export_quotes(path):
			message.text = temporary.last_error
			return
		message.text = "草稿已导出，保留角色、类别和阶段信息。"
