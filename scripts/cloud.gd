extends Node
## Website accounts. Guest play stays in the local progress file.
## Google sign-in stores that same progress under the player's account.
## Desktop builds never call the JavaScript bridge.

signal account_changed
signal save_arrived(data: Dictionary)

const API_KEY := "AIzaSyCyiYPfJ2oS2Dx4UTXzKVmbLgDVUUyHZYk"
const AUTH_DOMAIN := "n-vs-z-saves.firebaseapp.com"
const PROJECT_ID := "n-vs-z-saves"
const APP_ID := "1:594180242834:web:2c03ff1f34f96a4062554b"
const GOOGLE_CLIENT_ID := "594180242834-t0016tou7ua2ds2huboi4alj79lu6irf.apps.googleusercontent.com"

var signed_in: bool = false
var display_name: String = ""
var email: String = ""
var last_error: String = ""
var hold_push: bool = true

var _status: String = "boot"
var _uid: String = ""
var _last_save: String = ""
var _last_push: String = ""
var _wait: float = 0.0

const BOOT := """
(function(){
  if (window.__acct) return;
  window.__acct = {status:'boot', uid:'', name:'', email:'', error:'', saveJson:'', gen:0, started:false, want:false, cfg:null, auth:null, db:null, pendingToken:''};
  function clean(s) { return String(s || '').split('<<NV>>').join(' '); }
  function payloadOf(jwt) {
    try {
      var part = jwt.split('.')[1].split('-').join('+').split('_').join('/');
      while (part.length % 4) part += '=';
      return JSON.parse(atob(part));
    } catch (e) { return null; }
  }
  function takeHash() {
    var hash = window.location.hash || '';
    if (hash.indexOf('id_token=') < 0) return;
    var params = new URLSearchParams(hash.substring(1));
    var idToken = params.get('id_token') || '';
    var next = window.location.pathname + window.location.search;
    history.replaceState(null, '', next);
    if (!idToken) return;
    var body = payloadOf(idToken);
    var nonce = '';
    try { nonce = sessionStorage.getItem('nvsz_nonce') || ''; } catch (e2) {}
    try { sessionStorage.removeItem('nvsz_nonce'); } catch (e3) {}
    if (!body || (nonce && body.nonce && body.nonce !== nonce)) {
      window.__acct.error = 'Google sign-in did not finish.';
      return;
    }
    window.__acct.pendingToken = idToken;
  }
  takeHash();
  window.nvAcctState = function() {
    var a = window.__acct;
    var save = a.saveJson || '';
    a.saveJson = '';
    return [a.gen, a.status, clean(a.uid), clean(a.name), clean(a.email), clean(a.error), save].join('<<NV>>');
  };
  function loadScript(src, next, fail) {
    var tag = document.createElement('script');
    tag.src = src;
    tag.onload = next;
    tag.onerror = fail;
    document.head.appendChild(tag);
  }
  var srcs = [
    'https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js',
    'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth-compat.js',
    'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore-compat.js'
  ];
  function loadAt(i) {
    if (i >= srcs.length) { window.nvAcctTry(); return; }
    loadScript(srcs[i], function(){ loadAt(i + 1); }, function(){
      window.__acct.status = 'error';
      window.__acct.error = 'Could not reach Google.';
    });
  }
  function ios() {
    var ua = navigator.userAgent || '';
    if (ua.indexOf('iPad') >= 0 || ua.indexOf('iPhone') >= 0 || ua.indexOf('iPod') >= 0) return true;
    return navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
  }
  window.nvAcctStart = function(cfg) {
    window.__acct.cfg = cfg;
    window.__acct.want = true;
    if (typeof firebase !== 'undefined' && firebase.firestore) window.nvAcctTry();
    else loadAt(0);
  };
  function pullSave(a, user) {
    a.db.collection('saves').doc(user.uid).get().then(function(doc) {
      var data = doc.exists ? doc.data() : {};
      if (data && data.updated) delete data.updated;
      a.saveJson = JSON.stringify(data || {});
      a.gen += 1;
    }).catch(function() {
      a.error = 'Could not load the saved game.';
    });
  }
  function applyUser(a, user, fresh) {
    a.status = 'signed';
    a.uid = user.uid;
    a.name = user.displayName || user.email || 'Google';
    a.email = user.email || '';
    a.error = '';
    if (fresh) pullSave(a, user);
  }
  window.nvAcctTry = function() {
    var a = window.__acct;
    if (!a.want || a.started) return;
    if (typeof firebase === 'undefined' || !firebase.auth || !firebase.firestore) return;
    a.started = true;
    try {
      firebase.initializeApp(a.cfg);
      a.auth = firebase.auth();
      a.db = firebase.firestore();
      a.auth.setPersistence(firebase.auth.Auth.Persistence.LOCAL).catch(function(){});
      if (a.pendingToken) {
        var token = a.pendingToken;
        a.pendingToken = '';
        var cred = firebase.auth.GoogleAuthProvider.credential(token);
        a.auth.signInWithCredential(cred).catch(function() {
          a.error = 'Google sign-in did not finish.';
        });
      }
      a.auth.onAuthStateChanged(function(user) {
        if (user) {
          var fresh = a.uid !== user.uid;
          applyUser(a, user, fresh);
        } else {
          a.status = 'guest';
          a.uid = '';
          a.name = '';
          a.email = '';
        }
      });
    } catch (e) {
      a.status = 'error';
      a.error = 'Google sign-in is not ready.';
    }
  };
  function startRedirect() {
    var a = window.__acct;
    var clientId = a.cfg && a.cfg.clientId ? a.cfg.clientId : '';
    if (!clientId) {
      a.error = 'Google sign-in is not ready.';
      return;
    }
    var nonce = Math.random().toString(36).slice(2) + Date.now().toString(36);
    try { sessionStorage.setItem('nvsz_nonce', nonce); } catch (e4) {}
    var back = location.origin + location.pathname;
    var url = 'https://accounts.google.com/o/oauth2/v2/auth?client_id=' + encodeURIComponent(clientId)
      + '&redirect_uri=' + encodeURIComponent(back)
      + '&response_type=id_token'
      + '&scope=' + encodeURIComponent('openid email profile')
      + '&nonce=' + encodeURIComponent(nonce)
      + '&prompt=select_account'
      + '&state=nvsz';
    location.assign(url);
  }
  window.nvAcctSignIn = function() {
    var a = window.__acct;
    if (!a.auth) {
      a.error = 'Still connecting. Try again in a moment.';
      return;
    }
    var provider = new firebase.auth.GoogleAuthProvider();
    provider.setCustomParameters({prompt: 'select_account'});
    a.auth.signInWithPopup(provider).catch(function(err) {
      var code = err && err.code ? err.code : '';
      if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') return;
      startRedirect();
    });
  };
  window.nvAcctSignOut = function() {
    var a = window.__acct;
    if (!a.auth) return;
    a.auth.signOut().then(function(){ a.error = ''; }).catch(function() {
      a.error = 'Could not sign out.';
    });
  };
  function whole(n) {
    var v = Math.round(Number(n) || 0);
    if (v < 0) v = 0;
    return v;
  }
  window.nvAcctPush = function(data) {
    var a = window.__acct;
    if (!a.auth || !a.auth.currentUser || !a.db || !data) return '0';
    var body = {
      unlocked: whole(data.unlocked),
      cleared: whole(data.cleared),
      diamonds: whole(data.diamonds),
      saber_skin: !!data.saber_skin,
      saber_worn: String(data.saber_worn || 'none'),
      sheet_owned: String(data.sheet_owned || ''),
      sheet_worn: String(data.sheet_worn || ''),
      diamond_paid: whole(data.diamond_paid),
      code_paid: !!data.code_paid,
      updated: firebase.firestore.FieldValue.serverTimestamp()
    };
    a.db.collection('saves').doc(a.auth.currentUser.uid).set(body).catch(function() {
      a.error = 'Could not save to Google.';
    });
    return '1';
  };
})();
"""


func configured() -> bool:
	return API_KEY != "" and AUTH_DOMAIN != "" and PROJECT_ID != "" and APP_ID != "" and GOOGLE_CLIENT_ID != ""


func _ready() -> void:
	if not OS.has_feature("web"):
		set_process(false)
		return
	if not configured():
		set_process(false)
		return
	JavaScriptBridge.eval(BOOT, true)
	var cfg := JSON.stringify({
		"apiKey": API_KEY,
		"authDomain": AUTH_DOMAIN,
		"projectId": PROJECT_ID,
		"appId": APP_ID,
		"clientId": GOOGLE_CLIENT_ID,
	})
	JavaScriptBridge.eval("nvAcctStart(" + cfg + ")", true)


func _process(delta: float) -> void:
	if not OS.has_feature("web"):
		return
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = 0.25
	_poll()


func sign_in() -> void:
	if not OS.has_feature("web"):
		return
	if not configured():
		last_error = "Google sign-in is not connected yet."
		account_changed.emit()
		return
	JavaScriptBridge.eval("nvAcctSignIn()", true)


func sign_out() -> void:
	if not OS.has_feature("web") or not configured():
		return
	JavaScriptBridge.eval("nvAcctSignOut()", true)


func push(data: Dictionary) -> void:
	if not OS.has_feature("web") or not configured() or not signed_in or hold_push:
		return
	var json := JSON.stringify(data)
	if json == _last_push:
		return
	_last_push = json
	JavaScriptBridge.eval("nvAcctPush(" + json + ")", true)


func _poll() -> void:
	var raw: Variant = JavaScriptBridge.eval("nvAcctState()", true)
	var text := str(raw)
	if text == "" or text == "null":
		return
	var parts := text.split("<<NV>>", true)
	if parts.size() < 7:
		return
	var status := str(parts[1])
	var uid := str(parts[2])
	var name := str(parts[3])
	var mail := str(parts[4])
	var err := str(parts[5])
	var save_text := str(parts[6])
	var was_signed := signed_in
	var changed := status != _status or uid != _uid or err != last_error or name != display_name
	_status = status
	_uid = uid
	display_name = name
	email = mail
	last_error = err
	signed_in = status == "signed" and uid != ""
	if not signed_in:
		hold_push = true
		if was_signed:
			_last_push = ""
	if changed:
		account_changed.emit()
	if save_text == "" or save_text == _last_save:
		return
	_last_save = save_text
	var parsed: Variant = JSON.parse_string(save_text)
	if not (parsed is Dictionary):
		last_error = "Could not read the saved game."
		account_changed.emit()
		return
	hold_push = false
	save_arrived.emit(parsed)
