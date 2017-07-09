import 'dart:convert';

class LobbyInfo {
  final String name;
  final bool hasPassword;
  final int maxPlayers;
  final int numberOfPlayers;

  const LobbyInfo(
      this.name, this.hasPassword, this.maxPlayers, this.numberOfPlayers);

  factory LobbyInfo.fromJson(var json) {
    var list;

    if (json is List) {
      list = json;
    } else {
      list = JSON.decode(json) as List;
    }

    return new LobbyInfo(list[nameIndex], list[hasPasswordIndex],
        list[maxPlayersIndex], list[numberOfPlayersIndex]);
  }

  static const nameIndex = 0;
  static const hasPasswordIndex = 1;
  static const maxPlayersIndex = 2;
  static const numberOfPlayersIndex = 3;

  String toJson() =>
      JSON.encode([name, hasPassword, maxPlayers, numberOfPlayers]);
}
