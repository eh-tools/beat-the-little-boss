class_name PetTheme
extends RefCounted

const FONT: FontFile = preload("res://assets/fonts/fusion-pixel-12px-proportional.ttf")
const INK := Color("303247")
const CREAM := Color("fff4d9")
const GOLD := Color("ffe1a6")
const CORAL := Color("e79777")
const TEAL := Color("95e0d0")


static func font() -> FontFile:
	return FONT
