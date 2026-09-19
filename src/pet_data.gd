class_name PetData
extends RefCounted

const VERSION := 1
const CHARACTERS := ["male", "female"]
const CATEGORIES := ["idle", "hit", "plead"]

var preferences: Dictionary = _default_preferences()
var quotes: Array = default_quotes()
var last_error: String = ""

var _corrupt_paths := {}


func load_from(path: String) -> bool:
	last_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		if FileAccess.get_open_error() == ERR_FILE_NOT_FOUND:
			return true
		return _fail("无法读取配置：%s" % error_string(FileAccess.get_open_error()))
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	var parsed = parser.data if parse_error == OK else null
	if typeof(parsed) != TYPE_DICTIONARY:
		_corrupt_paths[path] = true
		return _fail("配置不是有效的 JSON 对象，原文件已保留")
	if parsed.get("version") != VERSION or typeof(parsed.get("preferences")) != TYPE_DICTIONARY or typeof(parsed.get("quotes")) != TYPE_ARRAY:
		_corrupt_paths[path] = true
		return _fail("配置格式或版本无效，原文件已保留")
	var checked_preferences := _validate_preferences(parsed.preferences)
	if checked_preferences.is_empty() or not _validate_rows(parsed.quotes):
		_corrupt_paths[path] = true
		return _fail(last_error + "；原文件已保留")
	preferences = checked_preferences
	quotes = _normalize_rows(parsed.quotes)
	_corrupt_paths.erase(path)
	return true


func save_to(path: String) -> bool:
	last_error = ""
	if _corrupt_paths.has(path):
		return _fail("拒绝覆盖损坏的原配置；请先恢复默认或另存为")
	var checked_preferences := _validate_preferences(preferences)
	if checked_preferences.is_empty() or not _validate_rows(quotes):
		return false
	var payload := {"version": VERSION, "preferences": checked_preferences, "quotes": _normalize_rows(quotes)}
	return _atomic_write(path, JSON.stringify(payload, "  "))


func export_quotes(path: String) -> bool:
	last_error = ""
	if not _validate_rows(quotes):
		return false
	return _atomic_write(path, JSON.stringify({"version": VERSION, "quotes": quotes}, "  "))


func import_quotes(path: String) -> bool:
	last_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("无法读取语录：%s" % error_string(FileAccess.get_open_error()))
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	var parsed = parser.data if parse_error == OK else null
	if typeof(parsed) != TYPE_DICTIONARY or parsed.get("version") != VERSION or typeof(parsed.get("quotes")) != TYPE_ARRAY:
		return _fail("语录文件格式或版本无效")
	return replace_quotes(parsed.quotes)


func replace_quotes(rows: Array) -> bool:
	last_error = ""
	if not _validate_rows(rows):
		return false
	quotes = _normalize_rows(rows)
	return true


func restore_defaults() -> void:
	preferences = _default_preferences()
	quotes = default_quotes()
	last_error = ""
	_corrupt_paths.clear()


func recover_corrupt(path: String) -> bool:
	last_error = ""
	if not _corrupt_paths.has(path):
		return true
	var backup := path + ".corrupt"
	if FileAccess.file_exists(backup):
		backup += "-%d" % Time.get_ticks_usec()
	var result := DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup))
	if result != OK:
		return _fail("无法保留损坏配置的备份：%s" % error_string(result))
	_corrupt_paths.erase(path)
	return true


func pick_quote(character: String, category: String, stage: int) -> String:
	var matches := _matching_quotes(quotes, character, category, stage)
	if matches.is_empty():
		matches = _matching_quotes(default_quotes(), character, category, stage)
	if matches.is_empty():
		return "……"
	return matches[randi() % matches.size()]


static func default_quotes() -> Array:
	var library := {
		"male": {
			"idle": [["下班？事情做完了吗", "这事你要负主要责任"], ["年轻人，讲点武德", "咳，手下留点情面"], ["今天可以不加班", "有事咱们好好商量"], ["锅我背，你先歇会", "我批！年假我都批！"], ["下班吧，我来收拾", "再也不临时开会了"]],
			"hit": [["你这是对领导的态度？", "我这是在锻炼你！"], ["哎哟！领带都歪了", "你怎么还真动手啊"], ["停停停，我撤回刚才的话", "方案挺好的，不用改了"], ["我不甩锅了，真的！", "加班费，双倍行不行"], ["我错了，饶了我", "我自己写周报行了吧"]],
			"plead": [["我错了，今天准点下班", "锅是我的，功劳是你的", "求你了，锤子先放下"]]
		},
		"female": {
			"idle": [["这个需求很简单吧？", "格局打开，饼会有的"], ["咖啡都洒出来了", "咱们先对齐一下情绪"], ["不催了，你慢慢做", "这个需求可以往后排"], ["不画饼了，现在就兑现", "今天不开复盘会了"], ["辛苦了，快去休息吧", "我保证，需求不再变了"]],
			"hit": [["这版感觉还是不太对", "再做五版让我挑挑"], ["眼镜！我的眼镜！", "先别打，咖啡是无辜的"], ["第一版就挺好的！", "别打了，我自己改文案"], ["最后一次改需求，真的", "预算有了，我这就批！"], ["我道歉，别打了", "不催了，不催了"]],
			"plead": [["我道歉，再也不画饼了", "需求我来挡，你去下班", "饼不画了，加薪安排上"]]
		}
	}
	var rows: Array = []
	for character in CHARACTERS:
		for category in CATEGORIES:
			var groups: Array = library[character][category]
			for index in groups.size():
				for text in groups[index]:
					rows.append({"character": character, "category": category, "stage": 4 if category == "plead" else index, "text": text})
	return rows


static func _default_preferences() -> Dictionary:
	return {
		"character": "male",
		"weapon": "hammer",
		"scale": 1.0,
		"sound": true,
		"volume": 0.25,
		"position": null,
		"topmost": true,
	}


func _validate_preferences(value: Dictionary) -> Dictionary:
	var required := ["character", "weapon", "scale", "sound", "volume", "position", "topmost"]
	for key in required:
		if not value.has(key):
			_fail("偏好缺少字段：%s" % key)
			return {}
	if typeof(value.character) != TYPE_STRING or value.character not in CHARACTERS:
		return _invalid_preference("character")
	if typeof(value.weapon) != TYPE_STRING or value.weapon not in ["hammer", "gloves"]:
		return _invalid_preference("weapon")
	if typeof(value.scale) not in [TYPE_INT, TYPE_FLOAT] or float(value.scale) not in [1.0, 1.5, 2.0]:
		return _invalid_preference("scale")
	if typeof(value.sound) != TYPE_BOOL or typeof(value.topmost) != TYPE_BOOL:
		return _invalid_preference("sound/topmost")
	if typeof(value.volume) not in [TYPE_INT, TYPE_FLOAT] or float(value.volume) < 0.0 or float(value.volume) > 1.0:
		return _invalid_preference("volume")
	if value.position != null:
		if typeof(value.position) != TYPE_ARRAY or value.position.size() != 2:
			return _invalid_preference("position")
		for coordinate in value.position:
			if typeof(coordinate) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(coordinate)):
				return _invalid_preference("position")
	return {
		"character": value.character,
		"weapon": value.weapon,
		"scale": float(value.scale),
		"sound": value.sound,
		"volume": float(value.volume),
		"position": value.position.duplicate() if value.position != null else null,
		"topmost": value.topmost,
	}


func _invalid_preference(field: String) -> Dictionary:
	_fail("偏好字段无效：%s" % field)
	return {}


func _validate_rows(rows: Array) -> bool:
	for index in rows.size():
		var row = rows[index]
		if typeof(row) != TYPE_DICTIONARY:
			return _fail("第 %d 条语录不是对象" % (index + 1))
		for key in ["character", "category", "stage", "text"]:
			if not row.has(key):
				return _fail("第 %d 条语录缺少 %s" % [index + 1, key])
		if typeof(row.character) != TYPE_STRING or row.character not in CHARACTERS:
			return _fail("第 %d 条语录角色无效" % (index + 1))
		if typeof(row.category) != TYPE_STRING or row.category not in CATEGORIES:
			return _fail("第 %d 条语录类别无效" % (index + 1))
		if typeof(row.stage) not in [TYPE_INT, TYPE_FLOAT] or float(row.stage) != floorf(float(row.stage)) or int(row.stage) < -1 or int(row.stage) > 4:
			return _fail("第 %d 条语录阶段无效" % (index + 1))
		if typeof(row.text) != TYPE_STRING or row.text.strip_edges().is_empty() or row.text.length() > 24:
			return _fail("第 %d 条语录文本须为 1–24 个字符" % (index + 1))
		for offset in row.text.length():
			var code: int = row.text.unicode_at(offset)
			if code < 32 or (code >= 127 and code <= 159):
				return _fail("第 %d 条语录不能包含换行或控制字符" % (index + 1))
	return true


func _normalize_rows(rows: Array) -> Array:
	var normalized: Array = []
	for row in rows:
		normalized.append({"character": row.character, "category": row.category, "stage": int(row.stage), "text": row.text})
	return normalized


func _matching_quotes(rows: Array, character: String, category: String, stage: int) -> Array[String]:
	var exact: Array[String] = []
	var general: Array[String] = []
	for row in rows:
		if row.character == character and row.category == category:
			if row.stage == stage:
				exact.append(row.text)
			elif row.stage == -1:
				general.append(row.text)
	return exact + general


func _atomic_write(path: String, content: String) -> bool:
	var absolute := ProjectSettings.globalize_path(path)
	var temporary := absolute + ".tmp"
	var backup := absolute + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("无法写入临时文件：%s" % error_string(FileAccess.get_open_error()))
	file.store_string(content)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary)
		return _fail("写入失败：%s" % error_string(write_error))
	var had_original := FileAccess.file_exists(absolute)
	if had_original:
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup)
		var backup_error := DirAccess.rename_absolute(absolute, backup)
		if backup_error != OK:
			DirAccess.remove_absolute(temporary)
			return _fail("无法备份原文件：%s" % error_string(backup_error))
	var replace_error := DirAccess.rename_absolute(temporary, absolute)
	if replace_error != OK:
		if had_original:
			DirAccess.rename_absolute(backup, absolute)
		DirAccess.remove_absolute(temporary)
		return _fail("无法完成原子写入：%s" % error_string(replace_error))
	return true


func _fail(message: String) -> bool:
	last_error = message
	return false
