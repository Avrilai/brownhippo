library client;

import 'common/message_type.dart';

import 'state/src/play/play.dart';
import 'state/state.dart';

import 'client_websocket.dart';
import 'toast.dart';

main() async {
  final client = new ClientWebSocket();

  client.on(MessageType.toast, toast);

  await client.start();

  StateManager.shared.addAll( {
    'login': new Login(client),
    'lobbies': new Lobbies(client),
    'create': new Create(client),
    'play': new Play(client)
  });

  StateManager.shared.pushState('login', '');
}