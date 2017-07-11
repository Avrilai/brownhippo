part of server;

class LoginManager {
  // shared instance
  static final shared = new LoginManager._internal();

  var _lobbies = <String, Lobby>{};
  var _socketForUsername = <ServerWebSocket, String>{};
  var _socketForLobby = <ServerWebSocket, Lobby>{};

  // create singleton
  LoginManager._internal();

  // returns true if socket is logged in
  bool containsSocket(ServerWebSocket socket) =>
      _socketForUsername.containsKey(socket);

  // returns true if username is logged in
  bool containsUsername(String username) =>
      _socketForUsername.containsValue(username);

  // returns true if lobby name exists
  bool containsLobbyName(String lobbyName) => _lobbies.containsKey(lobbyName);

  // returns true if socket is in lobby
  bool socketIsCurrentlyInLobby(ServerWebSocket socket) =>
      _socketForLobby.containsKey(socket);

  // returns lobby from socket
  Lobby lobbyFromSocket(ServerWebSocket socket) => _socketForLobby[socket];

  // returns lobby from name
  Lobby lobbyFromName(String lobbyName) => _lobbies[lobbyName];

  // returns username from socket
  String usernameFromSocket(ServerWebSocket socket) =>
      _socketForUsername[socket];

  // get all sockets
  getSockets() => _socketForUsername.keys;

  // get all lobbies
  getLobbies() => _lobbies.values;

  // get all usernames
  getUsernames() => _socketForUsername.values;

  // add lobby and alert others of new lobby
  addLobby(Lobby lobby) {
    _lobbies[lobby.name] = lobby;

    // send lobby info to others
    for (var socket in getSockets()) {
      socket.send(MessageType.lobbyInfo, lobby.getInfo().toJson());
    }
  }

  // logs in socket with username
  loginSocket(ServerWebSocket socket, String username) {
    // add user
    _socketForUsername[socket] = username;

    // alert successful login
    socket.send(MessageType.loginSuccesful);

    print('$username logged in');

    // TODO have the client request the info
    // send lobby info
    for (var lobby in getLobbies()) {
      socket.send(MessageType.lobbyInfo, lobby.getInfo().toJson());
    }
  }

  // logs out socket
  logoutSocket(ServerWebSocket socket) {
    final username = _socketForUsername.remove(socket);
    print('$username logged out');
  }

  // create lobby from info
  createLobby(ServerWebSocket socket, CreateLobbyInfo info) {
    final lobby = new Lobby.fromInfo(info);
    addLobby(lobby);

    enterLobby(socket, info.lobbyName);
  }

  // enter lobby
  enterLobby(ServerWebSocket socket, String lobbyName) {
    final lobby = _lobbies[lobbyName];

    _socketForLobby[socket] = lobby;
    lobby.addPlayer(socket, _socketForUsername[socket]);
    socket.send(MessageType.enterLobbySuccessful, lobbyName);
  }

  // enter lobby with password
  enterSecureLobby(ServerWebSocket socket, LoginInfo info) {
    final lobby = _lobbies[info.lobbyName];

    if (lobby.hasPassword && lobby.password != info.password) {
      socket.send(MessageType.toast, 'Password is incorrect');
      socket.send(MessageType.enterLobbyFailure);
      return;
    }

    enterLobby(socket, lobby.name);
  }

  exitLobbyFromSocket(ServerWebSocket socket) {
    final lobby = lobbyFromSocket(socket);
    lobby.removePlayer(socket);

    // check for empty lobby, ignore if default lobby
    if (lobby.isNotEmpty || lobby.isDefault) return;

    // remove empty lobby
    _lobbies.remove(lobby.name);
    print('closed lobby ${lobby.name}');

    // alert players of closed lobby
    for (var socket in getSockets()) {
      socket.send(MessageType.lobbyClosed, lobby.name);
    }
  }
}
