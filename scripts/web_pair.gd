extends RefCounted
## Pairs two website players through the public PeerJS broker.
## The first browser to claim a free room waits. The next one joins it.
## No address and no code. Desktop builds never call the JavaScript bridge.

static var _booted := false

const BOOT := """
window.__nv = window.__nv || {role:'', status:'search', inbox:[], open:false, peer:null, conn:null, busy:false, gen:0, passes:0, waitTimer:0, helloTimer:0, paired:false, down:0, blocked:0, badBrowser:false, latest:{}};
window.nvCloud = {secure:true, host:'0.peerjs.com', port:443, config:{iceServers:[
  {urls:['stun:stun.l.google.com:19302','stun:stun.cloudflare.com:3478','stun:freeturn.net:3478']},
  {urls:'turn:freeturn.net:3478', username:'free', credential:'free'},
  {urls:'turn:freeturn.net:3478?transport=tcp', username:'free', credential:'free'},
  {urls:'turns:freeturn.net:5349', username:'free', credential:'free'}
]}};
window.nvStop = function(silent) {
  var box = window.__nv;
  box.gen += 1;
  if (box.waitTimer) { clearTimeout(box.waitTimer); box.waitTimer = 0; }
  if (box.helloTimer) { clearInterval(box.helloTimer); box.helloTimer = 0; }
  box.open = false;
  box.busy = false;
  box.paired = false;
  box.role = '';
  if (box.conn) { try { box.conn.close(); } catch (e) {} }
  if (box.peer) { try { box.peer.destroy(); } catch (e2) {} }
  box.conn = null;
  box.peer = null;
  box.inbox = [];
  box.latest = {};
  if (!silent) box.status = 'closed';
};
window.nvSend = function(s) {
  var box = window.__nv;
  if (!box) return;
  var payload = s;
  try { payload = JSON.parse(s); } catch (e) {}
  var kind = payload && payload.t ? payload.t : '';
  if (kind === 'state' || kind === 'hand') {
    if (!box.latest) box.latest = {};
    box.latest[kind] = payload;
    return;
  }
  if (!box.conn || !box.open) return;
  try { box.conn.send(payload); } catch (e2) {}
};
window.nvFlush = function() {
  var box = window.__nv;
  if (!box || !box.conn || !box.open || !box.latest) return;
  var hand = box.latest.hand;
  var state = box.latest.state;
  box.latest.hand = null;
  box.latest.state = null;
  try { if (hand) box.conn.send(hand); } catch (e) {}
  try { if (state) box.conn.send(state); } catch (e2) {}
};
window.nvState = function() {
  window.nvFlush();
  var box = window.__nv;
  if (!box) return 'missing<<S>><<S>>0<<S>>';
  var lines = box.inbox;
  box.inbox = [];
  return box.status + '<<S>>' + box.role + '<<S>>' + (box.open ? '1' : '0') + '<<S>>' + lines.join('<<NL>>');
};
window.nvPush = function(d) {
  var line = typeof d === 'string' ? d : JSON.stringify(d);
  if (line) window.__nv.inbox.push(line);
};
window.nvEnsure = function(done) {
  if (typeof Peer !== 'undefined') { done(); return; }
  if (window.__nvFailed) { window.__nv.status = 'missing'; return; }
  if (window.__nvLoading) {
    var wait = setInterval(function() {
      if (typeof Peer !== 'undefined') { clearInterval(wait); done(); }
      else if (window.__nvFailed) { clearInterval(wait); window.__nv.status = 'missing'; }
    }, 100);
    return;
  }
  window.__nvLoading = true;
  var tag = document.createElement('script');
  tag.src = 'https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js';
  tag.onload = function() { done(); };
  tag.onerror = function() { window.__nvFailed = true; window.__nv.status = 'missing'; };
  document.head.appendChild(tag);
};
window.nvWire = function(conn, gen) {
  var box = window.__nv;
  if (box.conn) { try { conn.close(); } catch (e) {} return false; }
  box.conn = conn;
  conn.on('data', function(d) {
    if (gen !== window.__nv.gen) return;
    window.__nv.paired = true;
    if (window.__nv.helloTimer) { clearInterval(window.__nv.helloTimer); window.__nv.helloTimer = 0; }
    window.nvPush(d);
  });
  conn.on('close', function() {
    if (gen !== window.__nv.gen || window.__nv.conn !== conn) return;
    var paired = window.__nv.paired;
    window.__nv.conn = null;
    window.__nv.open = false;
    if (window.__nv.helloTimer) { clearInterval(window.__nv.helloTimer); window.__nv.helloTimer = 0; }
    if (paired) window.__nv.status = 'closed';
  });
  conn.on('error', function() {
    if (gen !== window.__nv.gen) return;
    if (!window.__nv.open) window.__nv.blocked += 1;
  });
  var greet = function() {
    if (gen !== window.__nv.gen || window.__nv.conn !== conn) return;
    window.__nv.open = true;
    if (window.__nv.waitTimer) { clearTimeout(window.__nv.waitTimer); window.__nv.waitTimer = 0; }
    if (window.__nv.helloTimer) clearInterval(window.__nv.helloTimer);
    window.__nv.helloTimer = setInterval(function() {
      if (gen !== window.__nv.gen || window.__nv.paired || window.__nv.conn !== conn) {
        clearInterval(window.__nv.helloTimer);
        window.__nv.helloTimer = 0;
        return;
      }
      try { conn.send({t:'hello'}); } catch (e) {}
    }, 400);
    try { conn.send({t:'hello'}); } catch (e2) {}
  };
  conn.on('open', greet);
  if (conn.open) greet();
  return true;
};
window.nvGuest = function(gen, room, waitMs, done) {
  if (gen !== window.__nv.gen) return;
  var peer = new Peer(window.nvCloud);
  var settled = false;
  var timer = setTimeout(function() { finish('fail'); }, 8000);
  function finish(result) {
    if (settled || gen !== window.__nv.gen) return;
    settled = true;
    clearTimeout(timer);
    if (result !== 'joined') { try { peer.destroy(); } catch (e) {} }
    done(result);
  }
  peer.on('open', function() {
    if (settled || gen !== window.__nv.gen) return;
    clearTimeout(timer);
    var conn = peer.connect('nvsz' + room, {reliable:true, serialization:'json'});
    timer = setTimeout(function() { finish('fail'); }, waitMs);
    conn.on('data', function(d) {
      if (settled || gen !== window.__nv.gen) return;
      if (!window.nvWire(conn, gen)) { finish('fail'); return; }
      window.__nv.peer = peer;
      window.__nv.open = true;
      window.__nv.role = 'guest';
      window.__nv.status = 'guest';
      window.__nv.paired = true;
      window.nvPush(d);
      finish('joined');
    });
    conn.on('close', function() { finish('fail'); });
    conn.on('error', function() { finish('fail'); });
  });
  peer.on('error', function(err) {
    if (settled || gen !== window.__nv.gen) return;
    var kind = err && err.type ? err.type : '';
    if (kind === 'browser-incompatible') { window.__nv.status = 'error'; window.__nv.badBrowser = true; finish('fail'); return; }
    if (kind === 'peer-unavailable') { finish('empty'); return; }
    window.__nv.down += 1;
    finish('fail');
  });
};
window.nvHost = function(gen, room, done) {
  if (gen !== window.__nv.gen) return;
  var peer = new Peer('nvsz' + room, window.nvCloud);
  var settled = false;
  function finish(ok) {
    if (settled || gen !== window.__nv.gen) return;
    settled = true;
    clearTimeout(timer);
    if (!ok) { try { peer.destroy(); } catch (e) {} }
    done(ok);
  }
  var timer = setTimeout(function() { finish(false); }, 5000);
  peer.on('open', function() {
    if (settled || gen !== window.__nv.gen) { try { peer.destroy(); } catch (e) {} return; }
    settled = true;
    clearTimeout(timer);
    window.__nv.peer = peer;
    window.__nv.role = 'host';
    window.__nv.status = 'host';
    peer.on('connection', function(conn) {
      if (gen !== window.__nv.gen) { try { conn.close(); } catch (e) {} return; }
      if (window.__nv.busy || window.__nv.open) { try { conn.close(); } catch (e2) {} return; }
      var drop = setTimeout(function() {
        if (window.__nv.conn !== conn) { try { conn.close(); } catch (e3) {} }
      }, 8000);
      conn.on('open', function() {
        clearTimeout(drop);
        if (gen !== window.__nv.gen || window.__nv.busy || window.__nv.open) { try { conn.close(); } catch (e4) {} return; }
        window.nvWire(conn, gen);
      });
      conn.on('error', function() { clearTimeout(drop); });
      conn.on('close', function() { clearTimeout(drop); });
    });
    peer.on('disconnected', function() {
      if (gen !== window.__nv.gen || window.__nv.conn) return;
      try { peer.reconnect(); } catch (e) { window.__nv.status = 'error'; }
    });
    done(true);
  });
  peer.on('error', function(err) {
    if (settled || gen !== window.__nv.gen) return;
    var kind = err && err.type ? err.type : '';
    if (kind === 'browser-incompatible') { window.__nv.status = 'error'; window.__nv.badBrowser = true; }
    else if (kind === 'unavailable-id' || kind === 'peer-unavailable') window.__nv.blocked += 1;
    else window.__nv.down += 1;
    finish(false);
  });
};
window.nvSeek = function(gen, room) {
  if (gen !== window.__nv.gen || window.__nv.badBrowser) return;
  if (room > 8) {
    window.__nv.passes += 1;
    if (window.__nv.passes < 3) { window.nvSeek(gen, 1); return; }
    window.__nv.status = (window.__nv.down > 0 && window.__nv.blocked === 0) ? 'error' : 'busy';
    return;
  }
  window.nvGuest(gen, room, 9000, function(result) {
    if (result === 'joined' || gen !== window.__nv.gen || window.__nv.badBrowser) return;
    window.nvHost(gen, room, function(hosted) {
      if (hosted || gen !== window.__nv.gen || window.__nv.badBrowser) return;
      window.nvGuest(gen, room, 9000, function(again) {
        if (again === 'joined' || gen !== window.__nv.gen || window.__nv.badBrowser) return;
        window.nvSeek(gen, room + 1);
      });
    });
  });
};
window.nvFind = function() {
  window.nvStop(true);
  var gen = window.__nv.gen;
  window.__nv.status = 'search';
  window.__nv.role = '';
  window.__nv.open = false;
  window.__nv.busy = false;
  window.__nv.passes = 0;
  window.__nv.down = 0;
  window.__nv.blocked = 0;
  window.__nv.badBrowser = false;
  window.__nv.paired = false;
  window.__nv.latest = {};
  if (window.__nv.helloTimer) { clearInterval(window.__nv.helloTimer); window.__nv.helloTimer = 0; }
  window.__nv.inbox = [];
  window.nvEnsure(function() {
    if (gen !== window.__nv.gen) return;
    if (typeof Peer === 'undefined') { window.__nv.status = 'missing'; return; }
    window.nvSeek(gen, 1);
  });
};
window.nvFind();
"""


static func start() -> void:
	var bridge = _bridge()
	if bridge == null:
		return
	if not _booted:
		_booted = true
		bridge.call("eval", BOOT, true)
		return
	bridge.call("eval", "nvFind()", true)


static func stop() -> void:
	var bridge = _bridge()
	if bridge == null or not _booted:
		return
	bridge.call("eval", "nvStop()", true)


static func mark_busy() -> void:
	var bridge = _bridge()
	if bridge == null or not _booted:
		return
	bridge.call("eval", "if(window.__nv)window.__nv.busy=true;", true)


static func send_text(text: String) -> void:
	var bridge = _bridge()
	if bridge == null or not _booted or text == "":
		return
	bridge.call("eval", "nvSend(" + JSON.stringify(text) + ")", true)


static func poll() -> Dictionary:
	var empty := {"status": "missing", "role": "", "open": false, "lines": []}
	var bridge = _bridge()
	if bridge == null or not _booted:
		return empty
	var raw = bridge.call("eval", "nvState()", true)
	var text := str(raw)
	if text == "" or text == "null" or text == "<null>":
		return empty
	var parts := text.split("<<S>>", true, 3)
	while parts.size() < 4:
		parts.append("")
	var lines: Array = []
	if str(parts[3]) != "":
		for line in str(parts[3]).split("<<NL>>"):
			if line != "":
				lines.append(line)
	return {
		"status": str(parts[0]),
		"role": str(parts[1]),
		"open": str(parts[2]) == "1",
		"lines": lines,
	}


static func _bridge():
	if not OS.has_feature("web"):
		return null
	return Engine.get_singleton("JavaScriptBridge")
