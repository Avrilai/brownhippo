library server;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' hide Point;

import 'package:args/args.dart';
import 'package:http_server/http_server.dart';

import '../../web/common/create_lobby_info.dart';
import '../../web/common/draw_websocket.dart';
import '../../web/common/login_info.dart';
import '../../web/common/lobby_info.dart';
import '../../web/common/message_type.dart';
import '../../web/common/draw_regex.dart';

part '../logic/game.dart';
part '../logic/lobby.dart';
part '../logic/word_similarity.dart';

part 'login_manager.dart';
part 'server_websocket.dart';
part 'socket_receiver.dart';
part 'validate_string.dart';

main(List<String> args) async {
  createDefaultLobbies();

  // bind to port 8080 by default
  int port = 8080;

  // get port number from environment variable if available
  if (Platform.environment['PORT'] != null) {
    port = int.parse(Platform.environment['PORT']);
  }

  // used for running the server in debug mode
  // serves dart files in debug mode,
  // compiles to js in release mode
  final parser = new ArgParser();
  parser.addOption('clientFiles', defaultsTo: 'web/');

  final results = parser.parse(args);
  final clientFiles = results['clientFiles'];

  // default home page
  final defaultPage = new File('$clientFiles/index.html');

  // serve static files
  final staticFiles = new VirtualDirectory(clientFiles);
  staticFiles
    ..jailRoot = false
    ..allowDirectoryListing = true
    ..directoryHandler = (dir, request) async {
      final indexUri = new Uri.file(dir.path).resolve('index.html');

      var file = new File(indexUri.toFilePath());

      if (!(await file.exists())) {
        file = defaultPage;
      }

      staticFiles.serveFile(file, request);
    };

  // bind server to localhost and specified port
  final server = await HttpServer.bind('0.0.0.0', port);

  print('server started at ${server.address.address}:${server.port}');

  // handle http requests and ws connections
  await for (HttpRequest request in server) {
    request.response.headers.set('cache-control', 'no-cache');

    // handle websocket connection
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = new ServerWebSocket.ugradeRequest(request);

      new SocketReceiver.handle(socket);

      continue;
    }

    // get path eg
    // www.helloworld.com/lobbyName
    //                    =========
    final path = request.uri.path.substring(1).trim();

    if (ValidateString.isValidLobbyName(path)) {
      staticFiles.serveFile(defaultPage, request);
    } else {
      staticFiles.serveRequest(request);
    }
  }
}


createDefaultLobbies() {
  LoginManager.shared
    ..addLobby(new Lobby('lobby1'))
    ..addLobby(new Lobby('lobby2'))
    ..addLobby(new Lobby('lobby3'))
    ..addLobby(new Lobby('lobby4'));
}

