extends SceneTree

const PetSession = preload("res://src/pet_session.gd")
const PetData = preload("res://src/pet_data.gd")
const BubbleClock = preload("res://src/bubble_clock.gd")

var failures := 0


func _init() -> void:
	test_session()
	test_data()
	test_clock()
	if failures == 0:
		print("core tests passed")
	quit(failures)


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func test_session() -> void:
	var session := PetSession.new()
	var events: Array = []
	session.attack_started.connect(func(event: Dictionary) -> void: events.append(event))
	session.set_roll_source(func() -> float: return 0.99)
	check(session.request_attack(), "idle hit starts")
	check(session.snapshot().progress == 1, "normal hit damages once")
	check(session.request_attack() and session.request_attack(), "two attacks queue")
	check(not session.request_attack(), "queue overflow is rejected")
	check(session.snapshot().progress == 1, "queued attacks do not settle early")
	session.advance(10.0)
	check(session.snapshot().progress == 2 and session.queued_count() == 1, "advance consumes at most one queued attack")
	session.advance(10.0)
	check(session.snapshot().progress == 3, "second queued attack executes later")
	check(not session.request_attack(false), "misses are rejected")

	session.cancel_attacks()
	session.set_roll_source(func() -> float: return 0.0)
	check(session.request_attack(), "critical starts")
	check(session.snapshot().progress == 5 and session.snapshot().bump == 1, "hammer critical adds two and bump")
	check(events[-1].critical and events[-1].direction == 0, "critical event shape")
	session.advance(1.0)
	session.set_roll_source(func() -> float: return 0.99)
	for index in range(4):
		check(session.request_attack(), "pity setup hit %d" % index)
		session.advance(1.0)
	session.request_attack()
	check(not events[-2].critical and events[-1].critical, "fifth non-critical roll is guaranteed critical")

	var stage_session := PetSession.new()
	stage_session.set_roll_source(func() -> float: return 0.99)
	for index in range(7):
		stage_session.request_attack()
		stage_session.advance(1.0)
	stage_session.set_roll_source(func() -> float: return 0.0)
	stage_session.request_attack()
	check(stage_session.snapshot().progress == 10 and stage_session.snapshot().stage == 1, "critical skips stage boundary")
	stage_session.cancel_attacks()
	stage_session.set_roll_source(func() -> float: return 0.99)
	while stage_session.snapshot().progress < 35:
		stage_session.request_attack()
		stage_session.advance(1.0)
	stage_session.set_roll_source(func() -> float: return 0.0)
	var cap_events: Array = []
	stage_session.attack_started.connect(func(event: Dictionary) -> void: cap_events.append(event))
	stage_session.request_attack()
	check(stage_session.snapshot().progress == 36 and cap_events[-1].finale, "damage clamps at cap and starts finale")
	stage_session.advance(2.0)
	stage_session.request_attack()
	check(cap_events[-1].terminal and not cap_events[-1].finale and cap_events[-1].duration == 0.25, "terminal feedback is short and finale is once-only")

	var recovery := PetSession.new()
	recovery.set_roll_source(func() -> float: return 0.0)
	var recovered: Array[String] = []
	check(recovery.has_signal("character_recovered"), "session exposes automatic recovery to the view")
	if recovery.has_signal("character_recovered"):
		recovery.connect("character_recovered", func(id: String) -> void: recovered.append(id))
	recovery.select_character("female")
	recovery.request_attack()
	recovery.advance(1.0)
	recovery.select_character("male")
	for index in range(18):
		recovery.request_attack()
		if index < 17: recovery.advance(1.0)
	check(recovery.snapshot().progress == 36, "automatic recovery starts from terminal stage")
	recovery.advance(6.19)
	check(recovery.snapshot().progress == 36, "kneeling remains visible for the full finale and five-second hold")
	recovery.advance(0.02)
	check(recovery.snapshot().progress == 0 and recovery.snapshot().bump == 0, "terminal character automatically recovers after the hold")
	check(recovery.snapshot("female").progress == 2, "automatic recovery does not clear the other character")
	check(recovered == ["male"], "automatic recovery emits once for the recovered character")

	var independent := PetSession.new()
	independent.set_roll_source(func() -> float: return 0.99)
	independent.request_attack()
	independent.request_attack()
	independent.select_character("female")
	check(independent.queued_count() == 0 and independent.snapshot().progress == 0, "switch cancels queue and keeps independent state")
	independent.select_weapon("gloves")
	independent.set_roll_source(func() -> float: return 0.0)
	independent.request_attack()
	check(independent.snapshot().chin == 1 and independent.snapshot().bump == 0, "gloves critical affects chin")
	independent.reset_all()
	check(independent.snapshot("male").progress == 0 and independent.snapshot("female").progress == 0 and independent.queued_count() == 0, "reset clears both states and attacks")
	var selected_reset := PetSession.new()
	selected_reset.set_roll_source(func() -> float: return 0.99)
	selected_reset.request_attack()
	selected_reset.select_character("female")
	selected_reset.request_attack()
	selected_reset.reset_character()
	check(selected_reset.snapshot("female").progress == 0 and selected_reset.snapshot("male").progress == 1, "selected reset preserves the other leader")
	check(selected_reset.queued_count() == 0 and not selected_reset.is_busy(), "selected reset cancels the current leader attack")
	check(PetSession.new().snapshot("male").progress == 0, "new sessions do not restore injuries")
	var weapon_change := PetSession.new()
	weapon_change.set_roll_source(func(): return 0.0)
	weapon_change.request_attack()
	weapon_change.select_weapon("gloves")
	check(weapon_change.is_busy(), "weapon change preserves in-flight animation duration")
	check(weapon_change.request_attack() and weapon_change.snapshot().progress == 2, "weapon change cannot allow an overlapping attack")
	var boundaries := PetSession.new()
	boundaries.set_roll_source(func(): return 0.0)
	for progress in range(2, 37, 2):
		boundaries.request_attack()
		var expected_stage := 0
		if progress >= 36: expected_stage = 4
		elif progress >= 27: expected_stage = 3
		elif progress >= 18: expected_stage = 2
		elif progress >= 9: expected_stage = 1
		check(boundaries.snapshot().stage == expected_stage, "critical progression stage at %d" % progress)
		boundaries.advance(2.0)


func test_data() -> void:
	var data := PetData.new()
	check(data.load_from("user://new-install-%d.json" % Time.get_ticks_usec()) and data.last_error.is_empty(), "first launch uses defaults without error")
	var original := data.quotes.duplicate(true)
	var with_general := original.duplicate(true)
	with_general.append({"character": "male", "category": "idle", "stage": -1, "text": "自定义通用语录"})
	check(data._matching_quotes(with_general, "male", "idle", 0).has("自定义通用语录"), "universal custom quotes remain eligible alongside stage defaults")
	var rows := [{"character": "male", "category": "hit", "stage": 2.0, "text": "别打了"}]
	check(data.replace_quotes(rows), "valid quote replacement")
	check(data.quotes[0].stage == 2 and data.pick_quote("male", "hit", 2) == "别打了", "numeric JSON stage normalizes")
	var unchanged := data.quotes.duplicate(true)
	check(not data.replace_quotes([{"character": "male", "category": "hit", "stage": 0, "text": "1234567890123456789012345"}]), "long quote rejected")
	check(data.quotes == unchanged, "invalid replacement is atomic")
	check(not data.replace_quotes([{"character": "robot", "category": "hit", "stage": 0, "text": "x"}]), "invalid fields rejected")
	check(not data.replace_quotes([{"character": "male", "category": "hit", "stage": 0, "text": "bad\nline"}]), "newline rejected")
	check(not data.replace_quotes([{"character": "male", "category": "hit", "stage": 0, "text": "   "}]), "blank imported quote rejected")
	check(data.pick_quote("female", "plead", 4) != "", "missing custom quote falls back")
	for character in ["male", "female"]:
		for stage in 5:
			var matches: Array = original.filter(func(row): return row.character == character and row.category == "idle" and row.stage == stage)
			check(matches.size() >= 2, "built-in idle lines rotate for every role/stage")

	var root := "user://core-test-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
	var config_path := root + "/pet.json"
	data.preferences.character = "female"
	data.preferences.position = [12.0, 34.0]
	check(data.save_to(config_path), "configuration saves")
	var loaded := PetData.new()
	check(loaded.load_from(config_path), "configuration loads")
	check(loaded.preferences.character == "female" and loaded.preferences.position == [12.0, 34.0] and loaded.quotes[0].stage == 2, "preferences and quotes roundtrip")
	var quotes_path := root + "/quotes.json"
	check(data.export_quotes(quotes_path), "quotes export")
	var imported := PetData.new()
	check(imported.import_quotes(quotes_path) and imported.quotes == data.quotes, "quotes import roundtrip")

	var corrupt_path := root + "/corrupt.json"
	var corrupt := FileAccess.open(corrupt_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var before := loaded.quotes.duplicate(true)
	check(not loaded.load_from(corrupt_path) and loaded.quotes == before, "malformed load preserves memory")
	check(not loaded.save_to(corrupt_path), "malformed source cannot be silently overwritten")
	var read_corrupt := FileAccess.open(corrupt_path, FileAccess.READ)
	check(read_corrupt.get_as_text() == "{broken", "corrupt original is preserved")
	read_corrupt.close()
	check(loaded.recover_corrupt(corrupt_path) and loaded.save_to(corrupt_path), "explicit recovery allows saving valid defaults")
	check(FileAccess.get_file_as_string(corrupt_path + ".corrupt") == "{broken", "explicit recovery preserves original in separate corrupt backup")
	check(not loaded.save_to(root + "/missing/child.json") and loaded.last_error != "", "write errors are observable")
	loaded.restore_defaults()
	check(loaded.quotes == original and loaded.preferences.character == "male", "restore resets quotes and preferences")


func test_clock() -> void:
	var clock := BubbleClock.new()
	clock.set_roll_source(func() -> float: return 0.0)
	check(not clock.advance(9.999), "idle is not due before lower bound")
	check(clock.advance(0.001), "idle is due at lower bound")
	clock.show_idle("idle")
	check(clock.visible and clock.text == "idle", "idle bubble displays")
	check(not clock.advance(1.999) and clock.visible, "bubble remains before duration boundary")
	clock.advance(0.001)
	check(not clock.visible, "bubble clears at duration boundary")
	clock.show_hit("hit")
	clock.show_idle("ignored")
	check(clock.text == "hit", "hit bubble has priority")
	clock.show_hit("too soon")
	check(clock.text == "hit", "hit refresh is rate limited")
	clock.advance(0.12)
	clock.show_hit("refreshed")
	check(clock.text == "refreshed", "hit refresh works at boundary")
	clock.clear()
	check(not clock.visible and clock.text == "", "clear resets bubble")
	clock.set_roll_source(func(): return 1.0)
	check(not clock.advance(14.999) and clock.advance(0.001), "upper idle boundary is 15 seconds")
	clock.show_idle("upper")
	clock.advance(2.999)
	check(clock.visible, "upper visible duration lasts 3 seconds")
	clock.advance(0.002)
	check(not clock.visible, "upper visible duration ends")
