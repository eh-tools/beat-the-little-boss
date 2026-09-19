class_name PetTheme
extends RefCounted
## Shared palette, control styles and generated pixel textures for the pet UI.

const FONT: FontFile = preload("res://assets/fonts/fusion-pixel-12px-proportional.ttf")

const INK := Color("303247")
const CREAM := Color("fff4d9")
const GOLD := Color("ffe1a6")
const CORAL := Color("e79777")
const TEAL := Color("95e0d0")
const SURFACE := Color("fff9e8")
const FILTER := Color("f3dfb6")
const LINE := Color("d4a476")
const MUTED := Color("8d5a62")
const ROW_SEPARATOR := Color("eed7ab")

const CONTROL_HEIGHT := 38
const SHADOW_OFFSET := 3
const CHECKBOX_SIZE := 14
const GRABBER_SIZE := 12
const SCROLLBAR_WIDTH := 10


static func font() -> FontFile:
	return FONT


## Dashed 2px rule drawn directly, used as the volume section separator.
class DashedRule extends Control:
	var thickness := 2
	var dash := 6
	var gap := 4
	var rule_color := LINE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x := 0.0
		while x < size.x:
			draw_rect(Rect2(x, 0.0, minf(float(dash), size.x - x), float(thickness)), rule_color)
			x += float(dash + gap)


static func flat_box(background: Color, border := Color(0, 0, 0, 0), border_width := 0, corner := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner)
	return style


static func clear_box() -> StyleBoxFlat:
	return flat_box(Color(0, 0, 0, 0))


## A control surface with the 2px ink border and 8px inner padding from the mockup.
static func control_box(background := SURFACE, border := INK, border_width := 2) -> StyleBoxFlat:
	var style := flat_box(background, border, border_width)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


## Primary action surface: ink border plus the approved 3px offset pixel shadow.
## Zero spread keeps the drawn block exactly 3px, matching the mockup's `box-shadow: 3px 3px`.
static func action_box(background: Color, border := INK) -> StyleBoxFlat:
	var style := control_box(background, border, 2)
	style.shadow_color = INK
	style.shadow_size = 0
	style.shadow_offset = Vector2(SHADOW_OFFSET, SHADOW_OFFSET)
	return style


## One quote row: cream surface closed by a 2px warm separator on its lower edge.
static func row_box(background := SURFACE) -> StyleBoxFlat:
	var style := flat_box(background)
	style.border_color = ROW_SEPARATOR
	style.border_width_bottom = 2
	return style


static func dashes(thickness := 2, dash := 6, gap := 4, rule_color := LINE) -> DashedRule:
	var rule := DashedRule.new()
	rule.name = "VolumeRule"
	rule.thickness = thickness
	rule.dash = dash
	rule.gap = gap
	rule.rule_color = rule_color
	rule.custom_minimum_size = Vector2(0, thickness)
	return rule


static func _blank(size: Vector2i) -> Image:
	return Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)


static func _fill(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)


static func _outline(image: Image, color: Color, width: int) -> void:
	_fill(image, Rect2i(0, 0, image.get_width(), width), color)
	_fill(image, Rect2i(0, image.get_height() - width, image.get_width(), width), color)
	_fill(image, Rect2i(0, 0, width, image.get_height()), color)
	_fill(image, Rect2i(image.get_width() - width, 0, width, image.get_height()), color)


static func transparent_icon() -> ImageTexture:
	return ImageTexture.create_from_image(_blank(Vector2i(1, 1)))


static func option_arrow() -> ImageTexture:
	var image := _blank(Vector2i(12, 8))
	var rows := [[0, 1, 8, 9], [2, 3, 6, 7], [4, 5]]
	for y in rows.size():
		for x in rows[y]:
			image.set_pixel(int(x) + 1, y + 2, INK)
	return ImageTexture.create_from_image(image)


static func checkbox_icon(checked: bool) -> ImageTexture:
	var image := _blank(Vector2i(CHECKBOX_SIZE, CHECKBOX_SIZE))
	_fill(image, Rect2i(0, 0, CHECKBOX_SIZE, CHECKBOX_SIZE), SURFACE)
	if checked:
		_fill(image, Rect2i(3, 3, CHECKBOX_SIZE - 6, CHECKBOX_SIZE - 6), GOLD)
	_outline(image, INK, 2)
	return ImageTexture.create_from_image(image)


static func slider_grabber(background := CORAL) -> ImageTexture:
	var image := _blank(Vector2i(GRABBER_SIZE, GRABBER_SIZE))
	_fill(image, Rect2i(0, 0, GRABBER_SIZE, GRABBER_SIZE), background)
	_outline(image, INK, 2)
	return ImageTexture.create_from_image(image)


static func build_settings_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	theme.set_stylebox("normal", "Button", action_box(TEAL))
	theme.set_stylebox("hover", "Button", action_box(GOLD))
	theme.set_stylebox("pressed", "Button", action_box(CORAL))
	theme.set_stylebox("disabled", "Button", action_box(FILTER))
	theme.set_stylebox("focus", "Button", clear_box())
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_stylebox("normal", "LineEdit", control_box())
	theme.set_stylebox("focus", "LineEdit", control_box(SURFACE, CORAL))
	theme.set_stylebox("read_only", "LineEdit", control_box(FILTER, LINE))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_color("selection_color", "LineEdit", GOLD)
	theme.set_stylebox("normal", "OptionButton", control_box())
	theme.set_stylebox("hover", "OptionButton", control_box(GOLD))
	theme.set_stylebox("pressed", "OptionButton", control_box(GOLD))
	theme.set_stylebox("disabled", "OptionButton", control_box(FILTER, LINE))
	theme.set_stylebox("focus", "OptionButton", clear_box())
	theme.set_color("font_color", "OptionButton", INK)
	theme.set_color("font_hover_color", "OptionButton", INK)
	theme.set_color("font_disabled_color", "OptionButton", MUTED)
	theme.set_icon("arrow", "OptionButton", option_arrow())
	theme.set_stylebox("panel", "PopupMenu", flat_box(CREAM, INK, 2, 6))
	theme.set_stylebox("hover", "PopupMenu", flat_box(GOLD, CORAL, 1, 2))
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", INK)
	theme.set_color("font_separator_color", "PopupMenu", MUTED)
	theme.set_icon("checked", "CheckButton", checkbox_icon(true))
	theme.set_icon("unchecked", "CheckButton", checkbox_icon(false))
	theme.set_icon("checked_disabled", "CheckButton", checkbox_icon(true))
	theme.set_icon("unchecked_disabled", "CheckButton", checkbox_icon(false))
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "CheckButton", clear_box())
	theme.set_color("font_color", "CheckButton", INK)
	theme.set_color("font_hover_color", "CheckButton", INK)
	theme.set_color("font_pressed_color", "CheckButton", INK)
	var track := flat_box(FILTER, INK, 2)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", flat_box(CORAL, INK, 2))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat_box(GOLD, INK, 2))
	theme.set_icon("grabber", "HSlider", slider_grabber())
	theme.set_icon("grabber_highlight", "HSlider", slider_grabber(GOLD))
	var scroll_track := flat_box(FILTER)
	var half := SCROLLBAR_WIDTH / 2
	scroll_track.content_margin_left = half
	scroll_track.content_margin_right = half
	scroll_track.content_margin_top = half
	scroll_track.content_margin_bottom = half
	theme.set_stylebox("scroll", "VScrollBar", scroll_track)
	theme.set_stylebox("grabber", "VScrollBar", flat_box(CORAL))
	theme.set_stylebox("grabber_highlight", "VScrollBar", flat_box(GOLD))
	theme.set_stylebox("grabber_pressed", "VScrollBar", flat_box(CORAL, LINE, 1))
	for icon in ["increment", "decrement", "increment_highlight", "decrement_highlight", "increment_pressed", "decrement_pressed"]:
		theme.set_icon(icon, "VScrollBar", transparent_icon())
	var separator := StyleBoxLine.new()
	separator.color = LINE
	separator.thickness = 2
	theme.set_stylebox("separator", "HSeparator", separator)
	theme.set_stylebox("separator", "VSeparator", separator)
	return theme
