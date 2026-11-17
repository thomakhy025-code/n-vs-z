extends Node

var _players: Array[AudioStreamPlayer] = []
var _bank: Dictionary = {}
var _index: int = 0
var _bed: AudioStreamPlayer
var _mood: String = ""


func _ready() -> void:
	for _i in 20:
		var player := AudioStreamPlayer.new()
		player.volume_db = -2.0
		add_child(player)
		_players.append(player)
	_bed = AudioStreamPlayer.new()
	_bed.volume_db = -14.0
	add_child(_bed)


func mood(place: String) -> void:
	var id := _mood_id(place)
	if id == _mood and _bed != null and _bed.playing:
		return
	_mood = id
	var stream := _stream(id)
	if stream == null or _bed == null:
		return
	if stream is AudioStreamWAV:
		var wave := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wave.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wave.loop_begin = 0
		var frames := int(round(wave.get_length() * float(wave.mix_rate)))
		wave.loop_end = maxi(1, frames)
		stream = wave
	_bed.stream = stream
	_bed.volume_db = -16.0 if id == "story_dread" or id == "story_war" else -13.0
	_bed.play()


func stop_mood() -> void:
	_mood = ""
	if _bed != null:
		_bed.stop()


func _mood_id(place: String) -> String:
	match place:
		"village", "lone", "vow", "bury":
			return "story_lonely"
		"camp", "council":
			return "story_hearth"
		"night", "banners", "omen", "ash", "low":
			return "story_dread"
		"war", "between":
			return "story_war"
		"cliff", "mountain", "quiet", "mist", "stone", "climb":
			return "story_high"
		_:
			return "story_road"


func play(id: String, pitch: float = 1.0, db: float = -2.0) -> void:
	var stream: AudioStream = _stream(id)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_index % _players.size()]
	_index += 1
	if player.playing and _index < 100000:
		player = _players[_index % _players.size()]
		_index += 1
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = db
	player.play()


func _stream(id: String) -> AudioStream:
	if _bank.has(id):
		return _bank[id] as AudioStream
	var path := "res://audio/%s.wav" % id
	if not ResourceLoader.exists(path):
		_bank[id] = null
		return null
	var loaded := load(path) as AudioStream
	_bank[id] = loaded
	return loaded
