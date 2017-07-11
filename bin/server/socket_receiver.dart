part of server;

class SocketReceiver {
  static final LoginManager _loginManager = LoginManager.shared;
  final ServerWebSocket _socket;

  SocketReceiver._internal(this._socket);

  factory SocketReceiver.handle(ServerWebSocket socket) {
    final sr = new SocketReceiver._internal(socket);

    sr._init();

    return sr;
  }

  _init() async {
    await _socket.start();

    _onStart();

    await _socket.done;

    _onClose();
  }

  _onStart() {
    _socket
      ..on(MessageType.login, _login)
      ..on(MessageType.createLobby, _createLobby)
      ..on(MessageType.enterLobby, _enterLobby)
      ..on(MessageType.enterLobbyWithPassword, _enterLobbyWithPassword)
      ..on(MessageType.exitLobby, _exitLobby);
  }

  _onClose() {
    // check if socket is logged in
    if (!_loginManager.containsSocket(_socket)) return;

    // remove socket from lobby if in lobby
    if (_loginManager.socketIsCurrentlyInLobby(_socket)) {
      _loginManager.exitLobbyFromSocket(_socket);
    }

    _loginManager.logoutSocket(_socket);
  }

  _login(String username) {
    // check for null username
    if (username == null || username.trim().isEmpty || username.toLowerCase() == 'null') {
      _socket.send(MessageType.toast, 'Invalid username');
      return;
    }

    // check if valid name
    if (!ValidateString.isValidUsername(username)) {
      _socket.send(MessageType.toast, 'Invalid username');
      return;
    }

    // check if username already exists
    if (_loginManager.containsUsername(username)) {
      _socket.send(MessageType.toast, 'Username taken');
      return;
    }

    // logout if currrently logged in
    if (_loginManager.containsSocket(_socket)) {

      // remove socket from lobby if in lobby
      if (_loginManager.socketIsCurrentlyInLobby(_socket)) {
        _loginManager.exitLobbyFromSocket(_socket);
      }

      _loginManager.logoutSocket(_socket);
    }

    _loginManager.loginSocket(_socket, username);
  }

  _createLobby(String json) {
    final info = new CreateLobbyInfo.fromJson(json);

    // check if lobby name already exists
    if (_loginManager.containsLobbyName(info.lobbyName)) {
      _socket.send(MessageType.toast, 'Lobby already exists');
      return;
    }

    if (!ValidateString.isValidLobbyName(info.lobbyName)) {
      _socket.send(MessageType.toast, 'Invalid lobby name');
      return;
    }

    _loginManager.createLobby(_socket, info);
  }

  _enterLobby(String lobbyName) {
    if (!_loginManager.containsLobbyName(lobbyName)) {
      _socket.send(MessageType.toast, 'Lobby doesn\'t exist');
      _socket.send(MessageType.enterLobbyFailure);
      return;
    }

    final lobby = _loginManager.lobbyFromName(lobbyName);

    if (lobby.hasPassword) {
      _socket.send(MessageType.requestPassword, lobbyName);
      return;
    }

    _loginManager.enterLobby(_socket, lobbyName);
  }

  _enterLobbyWithPassword(String json) {
    final info = new LoginInfo.fromJson(json);

    if (!_loginManager.containsLobbyName(info.lobbyName)) {
      _socket.send(MessageType.toast, 'Lobby doesn\'t exist');
      _socket.send(MessageType.enterLobbyFailure);
      return;
    }

    _loginManager.enterSecureLobby(_socket, info);
  }

  _exitLobby() {
    if (!_loginManager.socketIsCurrentlyInLobby(_socket)) return;

    _loginManager.exitLobbyFromSocket(_socket);
  }
}
