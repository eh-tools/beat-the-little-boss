extends Node
## Small original synthesized cartoon effects; no speech, streaming, or network.

var enabled := true
var volume := 0.25
var players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var next_player := 0

func _ready() -> void:
	for i in 4:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	for kind in ["hammer", "gloves", "critical", "collapse"]:
		sounds[kind] = _make_sound(kind)

func play_hit(event: Dictionary) -> void:
	if not enabled or volume <= 0.0:
		return
	var kind: String = "collapse" if event.finale else ("critical" if event.critical else event.weapon)
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = sounds[kind]
	player.volume_db = linear_to_db(volume * (0.5 if event.terminal else 1.0))
	player.play()

func _make_sound(kind: String) -> AudioStreamWAV:
	var rate := 22050
	var duration := 0.22
	if kind == "critical": duration = 0.4
	if kind == "collapse": duration = 0.72
	var bytes := PackedByteArray()
	bytes.resize(int(duration * rate) * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 417
	for i in bytes.size() / 2:
		var t := float(i) / rate
		var envelope := exp(-t * (12.0 if kind != "collapse" else 5.0))
		var wave := 0.0
		match kind:
			"hammer": wave = sin(TAU * (220.0 * t - 230.0 * t * t)) * 0.7 + random.randf_range(-0.2, 0.2)
			"gloves": wave = sin(TAU * 92.0 * t) * 0.6 + random.randf_range(-0.4, 0.4) * exp(-t * 28.0)
			"critical": wave = sin(TAU * (460.0 * t - 420.0 * t * t)) * 0.55 + sin(TAU * 130.0 * t) * 0.35
			"collapse": wave = random.randf_range(-0.7, 0.7) * (0.5 + 0.5 * sin(t * 70.0)) + sin(TAU * 65.0 * t) * 0.25
		var sample := int(clampf(wave * envelope * 0.65, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	return stream
