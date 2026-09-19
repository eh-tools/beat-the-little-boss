extends SceneTree

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	for screen in DisplayServer.get_screen_count():
		print("Screen ", screen, " work area=", DisplayServer.screen_get_usable_rect(screen), " dpi=", DisplayServer.screen_get_dpi(screen), " scale=", DisplayServer.screen_get_scale(screen))
	assert(ClassDB.class_exists("WindowsMousePassthrough"))
	assert(not WindowsMousePassthrough.set_passthrough(0, true))
	assert(not WindowsMousePassthrough.is_passthrough(0))
	var hwnd := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, root.get_window_id())
	assert(hwnd != 0, "Run with Windows display server, not --headless")
	assert(WindowsMousePassthrough.set_passthrough(hwnd, true))
	assert(WindowsMousePassthrough.is_passthrough(hwnd))
	assert(WindowsMousePassthrough.set_passthrough(hwnd, true))
	assert(WindowsMousePassthrough.set_passthrough(hwnd, false))
	assert(not WindowsMousePassthrough.is_passthrough(hwnd))
	# Dynamic invocation exercises the Variant ABI in addition to typed ptrcalls.
	assert(ClassDB.class_call_static("WindowsMousePassthrough", "set_passthrough", hwnd, true))
	assert(ClassDB.class_call_static("WindowsMousePassthrough", "is_passthrough", hwnd))
	assert(WindowsMousePassthrough.set_passthrough(hwnd, false))
	print("native passthrough tests passed")
	quit()
