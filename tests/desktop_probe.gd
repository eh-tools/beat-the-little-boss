extends SceneTree
## Native-input fixture using the real scene, an isolated config and a lasting bubble.

var app: Node

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	if not OS.get_cmdline_user_args().has("--config-path=res://.scratch/desktop-pet/ui-test.json"):
		push_error("Probe requires isolated ui-test config")
		quit(1)
		return
	app = load("res://src/main.tscn").instantiate()
	root.add_child(app)
	app.session.attack_started.connect(func(event): print("PROBE_ATTACK ", JSON.stringify(event)))
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(func(): app.bubble_clock.show_idle("气泡穿透测试：点击这里"))
	app.add_child(timer)
	timer.start()
	print("PROBE_READY progress=", app.session.snapshot().progress)
