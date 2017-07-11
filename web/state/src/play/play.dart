library play;

import '../../../client_websocket.dart';
import '../../../common/message_type.dart';
import '../../state.dart';

import 'dart:html' hide Point;

class Play extends State {
  final Element playCard = querySelector('#play-card');

  final Element canvasLeftLabel = querySelector('#canvas-left-label');
  final Element canvasMiddleLabel = querySelector('#canvas-middle-label');
  final Element canvasRightLabel = querySelector('#canvas-right-label');

  static final CanvasElement canvas = querySelector('#canvas');


  Play(ClientWebSocket client) : super(client);

  @override
  show() {
    playCard.style.display = '';
  }

  @override
  hide() {
    playCard.style.display = 'none';

    client.send(MessageType.exitLobby);
    
  }

}