extends Node
## Original procedural audio; no external recordings or global RNG use.
const RATE := 16000
const VOICES := 6
var clips: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var music_level: float = 0.35
var effects_level: float = 0.65
var last_played: Dictionary = {}
var next_voice: int = 0

func _ready() -> void:
	for kind in ["wind", "motor", "hook", "spark", "delivery"]:
		clips[kind] = _synthesize(kind)
	music = AudioStreamPlayer.new()
	music.stream = _synthesize("music")
	add_child(music)
	for i in range(VOICES):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	set_levels(music_level, effects_level)

func set_levels(background: float, effects: float) -> void:
	music_level = clampf(background, 0.0, 1.0)
	effects_level = clampf(effects, 0.0, 1.0)
	if is_instance_valid(music):
		music.volume_linear = music_level
	for player in players:
		player.volume_linear = effects_level
	if is_zero_approx(effects_level):
		stop_effects()

func start_music() -> void:
	if not music.playing:
		music.play()

func stop_effects() -> void:
	for player in players:
		player.stop()
	last_played.clear()
	next_voice = 0

func stop_all() -> void:
	stop_effects()
	music.stop()

func play_event(kind: String) -> void:
	if effects_level <= 0.0 or not clips.has(kind):
		return
	var now: int = Time.get_ticks_msec()
	if now - int(last_played.get(kind, -1000)) < 100:
		return
	last_played[kind] = now
	var player: AudioStreamPlayer = players[next_voice]
	next_voice = (next_voice + 1) % VOICES
	player.stop()
	player.stream = clips[kind]
	player.play()

func _synthesize(kind: String) -> AudioStreamWAV:
	var duration: float = {"music": 16.0, "wind": 0.8, "motor": 0.3, "hook": 0.35, "spark": 0.2, "delivery": 0.65}[kind]
	var count := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var noise := RandomNumberGenerator.new()
	noise.seed = 48271
	var filtered: float = 0.0
	var notes: Array[float] = [220.0, 261.63, 329.63, 293.66, 220.0, 196.0, 261.63, 246.94]
	for i in range(count):
		var t := float(i) / RATE
		var progress := t / duration
		var envelope := minf(t * 40.0, 1.0) * pow(1.0 - progress, 2.0)
		var sample: float = 0.0
		filtered = lerpf(filtered, noise.randf_range(-1.0, 1.0), 0.12)
		match kind:
			"wind":
				sample = filtered * sin(PI * progress) * 0.65
			"motor":
				sample = (sin(TAU * 75.0 * t) * 0.16 + filtered * 0.2) * envelope
			"hook":
				sample = (sin(TAU * (650.0 * t - 550.0 * t * t)) * 0.16 + filtered * 0.3) * envelope
			"spark":
				sample = (filtered * 0.9 + sin(TAU * 95.0 * t) * 0.2) * envelope
			"delivery":
				var frequency: float = [523.25, 659.25, 783.99][mini(int(t / 0.16), 2)]
				var attack := minf(fmod(t, 0.16) * 100.0, 1.0) if t < 0.48 else 1.0
				sample = sin(TAU * frequency * t) * envelope * attack * 0.24
			"music":
				var note: float = notes[mini(int(t / 2.0), 7)]
				var pulse := pow(sin(PI * fmod(t, 2.0) / 2.0), 2.0)
				# Soft minor arpeggio over a continuous low drone; ends at zero.
				sample = (sin(TAU * note * t) + 0.3 * sin(TAU * note * 2.0 * t)) * pulse * 0.075
				sample += sin(TAU * 110.0 * t) * pow(sin(PI * progress), 2.0) * 0.035
		data.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = data
	if kind == "music":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream

func _exit_tree() -> void:
	stop_all()
