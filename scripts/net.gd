extends Node

const PORT := 3001
const STUN := "stun:stun.l.google.com:19302"

signal lobby_changed
signal linked
signal dropped
signal loadout_got(side: int, ids: Array, sheets: Array, navy: bool)
signal begin_match(left: Array, right: Array, skins: Dictionary)
signal input_got(x: float, y: float, dragging: bool, sword: bool, shoot: bool)
signal buy_got(unit_id: String)
signal state_got(packet: Array)
signal pause_got
signal reselect_got
signal rematch_got

var role: String = ""
var status: String = "Host a match, or join one."
var code: String = ""
var live: bool = false
var guest_id: int = 0
var waiting_answer: bool = false

var _wired: bool = false
var _closing: bool = false
var _link: WebRTCPeerConnection
var _rtc: WebRTCMultiplayerPeer
var _ice: Array = []
var _ice_done: bool = false
var _ice_wait: float = 0.0
var _gathering: bool = false
var _published: bool = false
var _local_sdp: String = ""
var _local_type: String = ""


func _ready() -> void:
	_wire()


func _process(delta: float) -> void:
	if not _gathering or _published:
		return
	_ice_wait += delta
	if _local_sdp != "" and (_ice_done or _ice_wait >= 1.6):
		_publish_local()


func host_match() -> void:
	close_match()
	if OS.has_feature("web"):
		_web_host()
		return
	if not ClassDB.class_exists("ENetMultiplayerPeer"):
		status = "This build cannot host a match."
		lobby_changed.emit()
		return
	var server: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = server.create_server(PORT, 1)
	if err != OK:
		status = "Port %d is busy." % PORT
		lobby_changed.emit()
		return
	multiplayer.multiplayer_peer = server
	role = "host"
	status = "Hosting on port %d. On this computer the address is 127.0.0.1. Nearby, use %s." % [PORT, _lan_hint()]
	lobby_changed.emit()


func join_address(address: String) -> void:
	close_match()
	if not ClassDB.class_exists("ENetMultiplayerPeer"):
		status = "This build joins with a code, not an address."
		lobby_changed.emit()
		return
	var ip := address.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	var client: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = client.create_client(ip, PORT)
	if err != OK:
		status = "Could not join %s." % ip
		lobby_changed.emit()
		return
	multiplayer.multiplayer_peer = client
	role = "guest"
	status = "Joining %s on port %d." % [ip, PORT]
	lobby_changed.emit()


func apply_code(text: String) -> void:
	var data := _open(text)
	if data.is_empty():
		status = "That code could not be read."
		lobby_changed.emit()
		return
	var kind := str(data.get("kind", ""))
	if role == "host" and waiting_answer and kind == "answer":
		_accept_remote(data)
		status = "Connecting."
		lobby_changed.emit()
		return
	if role == "" and kind == "offer":
		_web_join(data)
		return
	status = "That code does not fit this side."
	lobby_changed.emit()


func close_match() -> void:
	_closing = true
	_shutdown_peer()
	role = ""
	live = false
	waiting_answer = false
	code = ""
	_closing = false


func _wire() -> void:
	if _wired:
		return
	_wired = true
	multiplayer.peer_connected.connect(_on_peer)
	multiplayer.peer_disconnected.connect(_on_peer_left)
	multiplayer.connection_failed.connect(_on_fail)
	multiplayer.server_disconnected.connect(_on_server_gone)


func _on_peer(id: int) -> void:
	if id != 1:
		guest_id = id
	if live:
		return
	live = true
	waiting_answer = false
	status = "Both ninjas are here. Choose 6."
	linked.emit()
	lobby_changed.emit()


func _on_peer_left(id: int) -> void:
	if _closing or not live:
		return
	if role == "host" and guest_id != 0 and id != guest_id:
		return
	_drop("The other ninja left.")


func _on_fail() -> void:
	if _closing or live:
		return
	status = "Could not join."
	_closing = true
	_shutdown_peer()
	role = ""
	_closing = false
	lobby_changed.emit()


func _on_server_gone() -> void:
	if _closing or not live:
		return
	_drop("The other ninja left.")


func _drop(message: String) -> void:
	status = message
	_closing = true
	_shutdown_peer()
	role = ""
	live = false
	waiting_answer = false
	_closing = false
	dropped.emit()
	lobby_changed.emit()


func _shutdown_peer() -> void:
	if _link != null:
		_link.close()
		_link = null
	_rtc = null
	_ice.clear()
	_ice_done = false
	_ice_wait = 0.0
	_gathering = false
	_published = false
	_local_sdp = ""
	_local_type = ""
	guest_id = 0
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func _web_host() -> void:
	if not ClassDB.class_exists("WebRTCMultiplayerPeer"):
		status = "This page cannot open a match."
		lobby_changed.emit()
		return
	var conn := _make_link()
	if conn == null:
		return
	_rtc = WebRTCMultiplayerPeer.new()
	_rtc.create_server()
	if _rtc.add_peer(conn, 2) != OK:
		status = "Could not open the match."
		lobby_changed.emit()
		return
	multiplayer.multiplayer_peer = _rtc
	role = "host"
	_gathering = true
	conn.create_offer()
	status = "Making a code."
	lobby_changed.emit()


func _web_join(data: Dictionary) -> void:
	var conn := _make_link()
	if conn == null:
		return
	_rtc = WebRTCMultiplayerPeer.new()
	_rtc.create_client(2)
	if _rtc.add_peer(conn, 1) != OK:
		status = "Could not join."
		lobby_changed.emit()
		return
	multiplayer.multiplayer_peer = _rtc
	role = "guest"
	_accept_remote(data)
	conn.poll()
	conn.create_answer()
	_gathering = true
	status = "Making the code to send back."
	lobby_changed.emit()


func _make_link() -> WebRTCPeerConnection:
	var conn := WebRTCPeerConnection.new()
	var err: Error = conn.initialize({
		"iceServers": [{"urls": [STUN, "stun:stun.cloudflare.com:3478"]}],
	})
	if err != OK:
		status = "Could not open a link."
		lobby_changed.emit()
		return null
	conn.session_description_created.connect(_on_description)
	conn.ice_candidate_created.connect(_on_ice)
	_link = conn
	return conn


func _on_description(kind: String, sdp: String) -> void:
	if _link == null:
		return
	_link.set_local_description(kind, sdp)
	_local_type = kind
	_local_sdp = sdp
	_ice_wait = 0.0


func _on_ice(media: String, index: int, name: String) -> void:
	if name == "":
		_ice_done = true
		return
	_ice.append([media, index, name])
	_ice_wait = 0.0


func _publish_local() -> void:
	if _published or _local_sdp == "":
		return
	_published = true
	_gathering = false
	code = _seal({"kind": _local_type, "sdp": _local_sdp, "ice": _ice})
	if _local_type == "offer":
		waiting_answer = true
		status = "Send this code to the other ninja. When a code comes back, paste it here and apply it."
	else:
		status = "Send this code back to the host."
	lobby_changed.emit()


func _accept_remote(data: Dictionary) -> void:
	if _link == null:
		return
	_link.set_remote_description(str(data.get("kind", "")), str(data.get("sdp", "")))
	var rows: Array = data.get("ice", [])
	for row in rows:
		if row is Array and (row as Array).size() >= 3:
			var ice_row: Array = row
			_link.add_ice_candidate(str(ice_row[0]), int(ice_row[1]), str(ice_row[2]))


func _lan_hint() -> String:
	var addresses: Array = IP.get_local_addresses()
	for raw in addresses:
		var ip := str(raw)
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"


func _seal(data: Dictionary) -> String:
	var raw := JSON.stringify(data).to_utf8_buffer()
	var zipped := raw.compress(FileAccess.COMPRESSION_DEFLATE)
	var head := PackedByteArray()
	head.resize(4)
	head.encode_u32(0, raw.size())
	return Marshalls.raw_to_base64(head + zipped)


func _open(text: String) -> Dictionary:
	var clean := ""
	for i in text.length():
		var ch := text.substr(i, 1)
		if ch != " " and ch != "\n" and ch != "\r" and ch != "\t":
			clean += ch
	if clean == "":
		return {}
	var raw := Marshalls.base64_to_raw(clean)
	if raw.size() < 5:
		return {}
	var size := int(raw.decode_u32(0))
	if size <= 0 or size > 200000:
		return {}
	var unzipped := raw.slice(4).decompress(size, FileAccess.COMPRESSION_DEFLATE)
	if unzipped.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(unzipped.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


@rpc("any_peer", "reliable", "call_local")
func share_loadout(ids: Array, sheets: Array, navy: bool) -> void:
	var who := multiplayer.get_remote_sender_id()
	if who == 0:
		who = multiplayer.get_unique_id()
	loadout_got.emit(0 if who == 1 else 1, ids, sheets, navy)


@rpc("authority", "reliable", "call_local")
func start_duel(left: Array, right: Array, skins: Dictionary) -> void:
	begin_match.emit(left, right, skins)


@rpc("any_peer", "unreliable")
func push_hand(x: float, y: float, dragging: bool, sword: bool, shoot: bool) -> void:
	if not multiplayer.is_server():
		return
	input_got.emit(x, y, dragging, sword, shoot)


@rpc("any_peer", "reliable")
func ask_buy(unit_id: String) -> void:
	if not multiplayer.is_server():
		return
	buy_got.emit(unit_id)


@rpc("authority", "unreliable")
func push_state(packet: Array) -> void:
	state_got.emit(packet)


@rpc("any_peer", "reliable")
func ask_pause() -> void:
	if not multiplayer.is_server():
		return
	pause_got.emit()


@rpc("any_peer", "reliable", "call_local")
func reselect() -> void:
	reselect_got.emit()


@rpc("any_peer", "reliable", "call_local")
func rematch() -> void:
	rematch_got.emit()
