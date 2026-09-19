extends Window
## A draft editor: changing rows never mutates live quotes until Save succeeds.

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
	title = "Quote Workshop · Beat the Little Boss"
	size = Vector2i(620, 660)
	min_size = Vector2i(570, 610)
	transient = true
	unresizable = false
	close_requested.connect(hide)
	var style_theme := Theme.new()
	style_theme.default_font = PetTheme.font()
	style_theme.default_font_size = 16
	theme = style_theme
	var background := ColorRect.new()
	background.color = PetTheme.INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	scroll.add_child(box)
	var heading := Label.new()
	heading.text = "让领导换一套说辞。"
	heading.add_theme_font_size_override("font_size", 27)
	heading.add_theme_color_override("font_color", Color("ffe1a6"))
	box.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "只留在这台电脑上。所有语录只显示文字，不朗读。"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("b7c9cb"))
	box.add_child(subtitle)
	box.add_child(HSeparator.new())
	var filters := HBoxContainer.new()
	box.add_child(filters)
	role = _option(["男领导", "女领导"], filters)
	category = _option(["待机", "受击", "求饶"], filters)
	role.item_selected.connect(func(_i): _refresh_list())
	category.item_selected.connect(func(_i): _refresh_list())
	lines = VBoxContainer.new()
	lines.custom_minimum_size.y = 185
	lines.add_theme_constant_override("separation", 4)
	box.add_child(lines)
	var entry_label := Label.new()
	entry_label.text = "语录内容 · 最多 24 字，气泡自动分为两行"
	entry_label.add_theme_font_size_override("font_size", 14)
	box.add_child(entry_label)
	input = LineEdit.new()
	input.placeholder_text = "例如：今天准点下班，我说的！"
	box.add_child(input)
	var row := HBoxContainer.new()
	box.add_child(row)
	stage = _option(["所有阶段", "正常", "轻微受伤", "明显受伤", "重伤", "求饶终态"], row)
	_button("新增", row, _add_row)
	_button("更新选中", row, _update_row)
	_button("删除", row, _delete_row)
	message = Label.new()
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 45
	message.add_theme_font_size_override("font_size", 14)
	message.add_theme_color_override("font_color", Color("ffd2a6"))
	box.add_child(message)
	box.add_child(HSeparator.new())
	var audio_row := HBoxContainer.new()
	box.add_child(audio_row)
	sound = CheckButton.new()
	sound.text = "音效"
	audio_row.add_child(sound)
	volume = HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 1
	volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_row.add_child(volume)
	var volume_label := Label.new()
	volume_label.custom_minimum_size.x = 50
	audio_row.add_child(volume_label)
	volume.value_changed.connect(func(value): volume_label.text = "%d%%" % value)
	var files := HBoxContainer.new()
	box.add_child(files)
	_button("导入文本…", files, func(): _choose_file(true))
	_button("导出文本…", files, func(): _choose_file(false))
	_button("恢复默认语录", files, _defaults)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)
	_button("关闭", footer, hide)
	var save := _button("保存设置", footer, _save)
	save.modulate = Color("95e0d0")
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

func _option(items: Array, parent: Node) -> OptionButton:
	var control := OptionButton.new()
	for item in items: control.add_item(item)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(control)
	return control

func _button(text_value: String, parent: Node, action: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = 36
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
		var tag: String = "通用" if int(row.stage) == -1 else ["正常", "轻伤", "明显", "重伤", "终态"][int(row.stage)]
		var button := Button.new()
		button.text = "[%s] %s" % [tag, row.text]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 34
		button.toggle_mode = true
		button.add_theme_color_override("font_color", PetTheme.CREAM)
		button.add_theme_color_override("font_hover_color", PetTheme.INK)
		button.add_theme_color_override("font_pressed_color", PetTheme.INK)
		button.add_theme_stylebox_override("normal", _row_style(Color("394050"), PetTheme.TEAL))
		button.add_theme_stylebox_override("hover", _row_style(PetTheme.GOLD, PetTheme.CORAL))
		button.add_theme_stylebox_override("pressed", _row_style(PetTheme.GOLD, PetTheme.CORAL))
		button.pressed.connect(_select_row.bind(i))
		lines.add_child(button)

func _row_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style

func _select_row(draft_index: int) -> void:
	selected_draft_index = draft_index
	var row: Dictionary = draft[draft_index]
	input.text = row.text
	stage.selected = int(row.stage) + 1

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
