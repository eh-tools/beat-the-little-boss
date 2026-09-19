extends SceneTree
## Runs the real scene and renderer using an isolated config path supplied after --.

var failures := 0
var app: Node
var output := "res://.scratch/desktop-pet"

func _init() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error(label)

## Windows rejects a topmost flag on an owned window, and the rejected flag then also
## breaks the later hide path. The bubble must inherit z-order from its owner instead.
func check_window_flags(label: String) -> void:
	check(app.bubble.transient, "speech window stays owned by the main window (%s)" % label)
	check(not app.bubble.always_on_top, "speech window never requests its own topmost flag (%s)" % label)
	check(app.root_window.always_on_top == app.data.preferences.topmost, "topmost lives on the owner window (%s)" % label)

func run() -> void:
	if not OS.get_cmdline_user_args().has("--config-path=user://app-test.json"):
		push_error("Run test_app with -- --config-path=user://app-test.json to protect real preferences")
		quit(1)
		return
	if FileAccess.file_exists("user://app-test.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://app-test.json"))
	var scene = load("res://src/main.tscn")
	app = scene.instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	app.set_process(false)
	check(app.session.selected == "male" and app.session.snapshot().progress == 0, "fresh launch shows intact male leader")
	check(not app.notice.visible, "fresh launch has no configuration error dialog")
	check(not app.bubble_clock.visible and not app.bubble.visible, "fresh launch does not flash an onboarding speech bubble")
	# Window 默认 visible = true。语录工坊若等到 _ready() 才隐藏, add_child() 入树那一刻
	# Godot 就已经在屏幕左上角创建并显示了一个 620x660 的原生窗口, 之后才销毁;
	# DWM 合成到那几毫秒就是启动时一闪而过的黑/白方块。
	var fresh_settings = load("res://src/settings_window.gd").new()
	check(not fresh_settings.visible, "quote workshop is hidden before it enters the tree")
	fresh_settings.free()
	check(not app.settings.visible, "quote workshop stays hidden until the user opens it")
	check(not ProjectSettings.get_setting("application/boot_splash/show_image"), "export does not show the default Godot boot image")
	check(ProjectSettings.get_setting("application/boot_splash/bg_color").a == 0.0, "boot splash background is transparent")
	check(ProjectSettings.get_setting("display/window/size/window_width_override") == 1, "startup window stays one pixel wide until the scene is ready")
	check(ProjectSettings.get_setting("display/window/size/window_height_override") == 1, "startup window stays one pixel tall until the scene is ready")
	check(app.root_window.transparent and app.root_window.borderless and app.root_window.always_on_top, "desktop window flags configured")
	check(app.bubble.mouse_passthrough and app.bubble.unfocusable, "speech window never takes input or focus")
	var native_handle := DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE, root.get_window_id())
	app._set_native_passthrough(root, true)
	check(WindowsMousePassthrough.is_passthrough(native_handle), "native main window passes input to other processes")
	app._set_native_passthrough(root, false)
	check(not WindowsMousePassthrough.is_passthrough(native_handle), "native main window regains input over the leader")
	check(not app.native_error_shown, "native flags apply without errors")
	check_window_flags("startup")
	app.bubble_clock.show_hit("气泡位置检查")
	app._update_bubble()
	var visible_head_top: int = root.position.y + int((16.0 + 29.0) * app.zoom)
	check(app.bubble.position.y + app.bubble.size.y >= visible_head_top - int(6.0 * app.zoom), "speech bubble sits close to the visible head")
	var drag_start: Vector2i = root.position
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2(95, 75)
	app._input(mouse_down)
	mouse_down = null
	check(app.pressed and app.press_screen == drag_start + Vector2i(95, 75), "press uses the event position even if OS cursor has already moved")
	app._update_drag(app.press_screen + Vector2i(25, 15))
	check(app.dragging and root.position == drag_start + Vector2i(25, 15), "fast drag updates position before a frame is processed")
	check(app.session.snapshot().progress == 0, "drag never attacks")
	app.pressed = false
	app.dragging = false
	app.sounds.enabled = false
	var terminal_entries := [0]
	app.session.attack_started.connect(func(event):
		if event.finale: terminal_entries[0] += 1)
	for role_id in [10, 11]:
		app._menu_action(role_id)
		for weapon_id in [20, 21]:
			app._menu_action(weapon_id)
			app.session.set_roll_source(func(): return 0.99)
			app.session.request_attack()
			app.session.advance(1.0)
			app.session.set_roll_source(func(): return 0.0)
			app.session.request_attack()
			await create_timer(0.75).timeout
			app.session.advance(1.0)
		while app.session.snapshot().progress < 36:
			app.session.request_attack()
			app.session.advance(1.3)
		await create_timer(1.3).timeout
		check(app.session.snapshot().stage == 4, "complete round reaches terminal stage")
		check(app.session.snapshot().bump > 0 and app.session.snapshot().chin > 0, "both local critical injuries retained")
		var before: int = terminal_entries[0]
		app.session.request_attack()
		app.session.advance(1.0)
		check(app.session.snapshot().progress == 36 and terminal_entries[0] == before, "terminal clicking does not replay collapse")
		app.session.advance(3.91)
		check(app.session.snapshot().progress == 0 and app.pet.state.progress == 0, "terminal character automatically recovers and refreshes the view")
	check(terminal_entries[0] == 2, "one finale per leader")
	app._menu_action(60)
	check(app.session.snapshot("male").progress == 0 and app.session.snapshot("female").progress == 0, "menu reset restores both leaders")
	for option in [30, 31, 32]:
		app._menu_action(option)
		check(app.root_window.size == Vector2i(Vector2(192, 212) * app.zoom), "scale menu updates physical window size")
		check_window_flags("scale %.1f" % app.zoom)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("app-scale-%s.png" % str(app.zoom)))
	app._menu_action(40)
	check(not app.data.preferences.topmost, "topmost menu item turns the preference off")
	check_window_flags("topmost off")
	app._menu_action(40)
	check(app.data.preferences.topmost, "topmost menu item turns the preference back on")
	check_window_flags("topmost on")
	app._menu_action(50)
	await process_frame
	await RenderingServer.frame_post_draw
	app.settings.get_texture().get_image().save_png(output.path_join("settings.png"))
	app.settings.input.text = "今天准时下班"
	app.settings._add_row()
	app.settings._save()
	check(app.data.last_error.is_empty(), "settings save succeeds through connected UI signal")
	var fresh_data = load("res://src/pet_data.gd").new()
	check(fresh_data.load_from("user://app-test.json"), "new application data loads saved preferences")
	check(fresh_data.preferences.character == "female" and fresh_data.preferences.scale == 2.0, "role and scale persist")
	check(fresh_data.quotes == app.data.quotes, "edited quotes persist")
	var fresh_session = load("res://src/pet_session.gd").new()
	check(fresh_session.snapshot("male").progress == 0 and fresh_session.snapshot("female").progress == 0, "next run starts intact")
	app.settings.hide()
	app._menu_action(70)
	await process_frame
	check(root.mode == Window.MODE_MINIMIZED and not app.bubble.visible, "hide minimizes and removes bubble")
	check_window_flags("after hide")
	root.mode = Window.MODE_WINDOWED
	await process_frame
	check(root.visible, "restore retains main window")
	app.queue_free()
	await process_frame
	if failures == 0: print("app integration tests passed")
	quit(failures)
