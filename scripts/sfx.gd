extends Node

var _players: Array[AudioStreamPlayer] = []
var _bank: Dictionary = {}
var _index: int = 0
var _bed: AudioStreamPlayer
var _voice: AudioStreamPlayer
var _mood: String = ""
var _voice_len: float = 0.0
const SHOUT_DB := 6.0


func _ready() -> void:
	for _i in 20:
		var player := AudioStreamPlayer.new()
		player.volume_db = -2.0
		add_child(player)
		_players.append(player)
	_bed = AudioStreamPlayer.new()
	_bed.volume_db = -14.0
	add_child(_bed)
	_voice = AudioStreamPlayer.new()
	_voice.volume_db = -2.0
	add_child(_voice)


func _process(_delta: float) -> void:
	if _bed == null or _mood == "":
		return
	if _voice != null and _voice.playing:
		_bed.volume_db = -22.0
	else:
		_bed.volume_db = _mood_db(_mood)


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
	_bed.volume_db = _mood_db(id)
	_bed.play()


func narrate(line: String) -> void:
	_voice_len = 0.0
	if _voice != null and _voice.playing:
		_voice.stop()
	if line == "" or _voice == null:
		return
	var stream := _stream("tale_" + line.md5_text().substr(0, 12))
	if stream == null:
		return
	_voice.stream = stream
	_voice.pitch_scale = 1.0
	_voice.volume_db = -2.0
	_voice.play()
	_voice_len = stream.get_length()


func narration_length() -> float:
	return _voice_len


func speak(id: String) -> float:
	_voice_len = 0.0
	if _voice != null and _voice.playing:
		_voice.stop()
	if id == "" or _voice == null:
		return 0.0
	var stream := _stream(id)
	if stream == null:
		return 0.0
	_voice.stream = stream
	_voice.pitch_scale = 1.0
	var loud: float = -2.0
	if id.begins_with("say_"):
		loud = SHOUT_DB
	_voice.volume_db = loud
	_voice.play()
	_voice_len = stream.get_length()
	return _voice_len


func hush() -> void:
	_voice_len = 0.0
	if _voice != null:
		_voice.stop()


func stop_mood() -> void:
	_mood = ""
	_voice_len = 0.0
	if _bed != null:
		_bed.stop()
	if _voice != null:
		_voice.stop()


func _mood_db(id: String) -> float:
	if id == "story_dread" or id == "story_war":
		return -16.0
	return -13.0


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
		path = "res://audio/%s.mp3" % id
	if not ResourceLoader.exists(path):
		_bank[id] = null
		return null
	var loaded := load(path) as AudioStream
	_bank[id] = loaded
	return loaded
