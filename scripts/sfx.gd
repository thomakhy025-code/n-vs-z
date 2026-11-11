extends Node

var _players: Array[AudioStreamPlayer] = []
var _bank: Dictionary = {}
var _index: int = 0


func _ready() -> void:
	for _i in 20:
		var player := AudioStreamPlayer.new()
		player.volume_db = -2.0
		add_child(player)
		_players.append(player)


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
