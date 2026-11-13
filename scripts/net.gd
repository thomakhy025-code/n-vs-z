extends Node

const WebPair = preload("res://scripts/web_pair.gd")

const PORT := 3001

signal lobby_changed
signal linked
signal dropped
signal loadout_got(side: int, ids: Array, sheets: Array, navy: bool)
signal begin_match(left: Array, right: Array, skins: Dictionary)
signal input_got(x: float, y: float, dragging: bool, sword: bool, shoot: bool)
signal buy_got(unit_id: String)
signal state_got(packet: Array)
signal arrow_got(payload: Array)
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
var _browser: bool = false
var _browser_note: String = ""


func _ready() -> void:
	_wire()
	if OS.has_feature("web"):
		status = "Press Find opponent. The game looks for one other ninja and connects."


func _process(_delta: float) -> void:
	if _browser:
		_poll_browser()


func host_match() -> void:
	close_match()
	if OS.has_feature("web"):
		find_opponent()
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


func find_opponent() -> void:
	close_match()
	if not OS.has_feature("web"):
		status = "On this computer, press Host, then Join with the address."
		lobby_changed.emit()
		return
	_browser = true
	_browser_note = ""
	status = "Looking for an opponent..."
	lobby_changed.emit()
	WebPair.start()


func close_match() -> void:
	_closing = true
	_browser = false
	_browser_note = ""
	WebPair.stop()
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
	_browser = false
	WebPair.stop()
	_shutdown_peer()
	role = ""
	live = false
	waiting_answer = false
	_closing = false
	dropped.emit()
	lobby_changed.emit()


func _shutdown_peer() -> void:
	guest_id = 0
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()


func _poll_browser() -> void:
	var state := WebPair.poll()
	var js_status := str(state.get("status", ""))
	var js_role := str(state.get("role", ""))
	var open := bool(state.get("open", false))
	if not live:
		if js_status == "closed":
			_browser = false
			WebPair.stop()
			_note("Could not reach an opponent. Press Find opponent to try again.")
		elif js_status == "busy":
			_note("Matches are full right now. Press Find opponent to try again.")
		elif js_status == "missing":
			_note("The match service did not load. Refresh the page and press Find opponent again.")
		elif js_status == "error":
			_note("Could not reach the match service. Press Find opponent to try again.")
		elif open and (js_role == "host" or js_role == "guest"):
			role = "guest" if js_role == "guest" else "host"
			guest_id = 2 if role == "host" else 0
			live = true
			status = "Both ninjas are here. Choose 6."
			WebPair.mark_busy()
			linked.emit()
			lobby_changed.emit()
		elif js_status == "host":
			_note("Waiting for one opponent.")
		elif js_status == "search":
			_note("Looking for an opponent...")
	elif js_status == "closed":
		_drop("The other ninja left.")
		return
	var lines: Array = state.get("lines", [])
	for line in lines:
		_browser_line(str(line))


func _note(message: String) -> void:
	if message == _browser_note:
		return
	_browser_note = message
	status = message
	lobby_changed.emit()


func _browser_line(line: String) -> void:
	var parsed: Variant = JSON.parse_string(line)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var msg: Dictionary = parsed
	var kind := str(msg.get("t", ""))
	if kind == "loadout":
		var ids: Variant = msg.get("ids", [])
		var sheets: Variant = msg.get("sheets", [])
		var id_list: Array = ids if ids is Array else []
		var sheet_list: Array = sheets if sheets is Array else []
		loadout_got.emit(int(msg.get("side", 1)), id_list, sheet_list, bool(msg.get("navy", false)))
	elif kind == "start" and role == "guest":
		var left: Variant = msg.get("left", [])
		var right: Variant = msg.get("right", [])
		var skins: Variant = msg.get("skins", {})
		var left_list: Array = left if left is Array else []
		var right_list: Array = right if right is Array else []
		var skin_map: Dictionary = skins if skins is Dictionary else {}
		begin_match.emit(left_list, right_list, skin_map)
	elif kind == "hand" and role == "host":
		input_got.emit(float(msg.get("x", 0.0)), float(msg.get("y", 0.0)), bool(msg.get("dragging", false)), bool(msg.get("sword", false)), bool(msg.get("shoot", false)))
	elif kind == "buy" and role == "host":
		buy_got.emit(str(msg.get("id", "")))
	elif kind == "state" and role == "guest":
		var packet: Variant = msg.get("p", [])
		if packet is Array:
			state_got.emit(packet)
	elif kind == "arrow" and role == "guest":
		var shot: Variant = msg.get("p", [])
		if shot is Array:
			arrow_got.emit(shot)
	elif kind == "pause" and role == "host":
		pause_got.emit()
	elif kind == "reselect":
		reselect_got.emit()
	elif kind == "rematch":
		rematch_got.emit()


func _send(msg: Dictionary) -> void:
	WebPair.send_text(JSON.stringify(msg))


func announce_loadout(ids: Array, sheets: Array, navy: bool) -> void:
	if _browser:
		var side := 0 if role == "host" else 1
		loadout_got.emit(side, ids, sheets, navy)
		_send({"t": "loadout", "side": side, "ids": ids, "sheets": sheets, "navy": navy})
		return
	share_loadout.rpc(ids, sheets, navy)


func announce_start(left: Array, right: Array, skins: Dictionary) -> void:
	if _browser:
		begin_match.emit(left, right, skins)
		_send({"t": "start", "left": left, "right": right, "skins": skins})
		return
	start_duel.rpc(left, right, skins)


func announce_hand(x: float, y: float, dragging: bool, sword: bool, shoot: bool) -> void:
	if role != "guest":
		return
	if _browser:
		_send({"t": "hand", "x": x, "y": y, "dragging": dragging, "sword": sword, "shoot": shoot})
		return
	push_hand.rpc_id(1, x, y, dragging, sword, shoot)


func announce_buy(unit_id: String) -> void:
	if role != "guest":
		return
	if _browser:
		_send({"t": "buy", "id": unit_id})
		return
	ask_buy.rpc_id(1, unit_id)


func announce_arrow(payload: Array) -> void:
	if role != "host":
		return
	if _browser:
		_send({"t": "arrow", "p": payload})
		return
	if guest_id < 2:
		return
	show_arrow.rpc_id(guest_id, payload)


func announce_state(packet: Array) -> void:
	if role != "host":
		return
	if _browser:
		_send({"t": "state", "p": packet})
		return
	if guest_id < 2:
		return
	push_state.rpc_id(guest_id, packet)


func announce_pause() -> void:
	if _browser:
		_send({"t": "pause"})
		return
	ask_pause.rpc_id(1)


func announce_reselect() -> void:
	if _browser:
		reselect_got.emit()
		_send({"t": "reselect"})
		return
	reselect.rpc()


func announce_rematch() -> void:
	if _browser:
		rematch_got.emit()
		_send({"t": "rematch"})
		return
	rematch.rpc()


func _lan_hint() -> String:
	var addresses: Array = IP.get_local_addresses()
	for raw in addresses:
		var ip := str(raw)
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"


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


@rpc("authority", "reliable")
func show_arrow(payload: Array) -> void:
	arrow_got.emit(payload)


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
