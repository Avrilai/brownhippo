part of server;

class Lobby {
  final String name;
  final String password;
  final bool hasPassword;
  final int maxPlayers;
  final Map<ServerWebSocket, String> _players = {};

  final bool isDefault;

  Game game;

  Lobby(this.name,
      {this.password = '', this.maxPlayers = 15, this.isDefault = false})
      : hasPassword = password.isNotEmpty {
    game = new Game(this);
  }

  factory Lobby.fromInfo(CreateLobbyInfo info) => new Lobby(info.lobbyName,
      password: info.password, maxPlayers: info.maxPlayers);

  bool get isNotEmpty => _players.isNotEmpty;

  getInfo() => new LobbyInfo(name, hasPassword, maxPlayers, _players.length);

  // add player to the lobby
  addPlayer(ServerWebSocket socket, String username) {
    // add player to game
    _players[socket] = username;
  }

  // remove player from the lobby
  removePlayer(ServerWebSocket socket) {
    final username = usernameFromSocket(socket);

    print('$username left lobby $name');

    _players.remove(socket);
  }

  sendToAll(MessageType type, {var val, ServerWebSocket excludedSocket}) {
    // send to all players in lobby except for the excluded socket
    for (var socket in _players.keys.where((s) => s != excludedSocket)) {
      socket.send(type, val);
    }
  }

  usernameFromSocket(ServerWebSocket socket) => _players[socket];
}
