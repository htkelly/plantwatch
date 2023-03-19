import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../utils/constants.dart';

main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  var env = DotEnv(includePlatformEnvironment: true)..load();
  int port = 8085;
  var server = await HttpServer.bind(env['API_SERVER_IP'], port);
  Db db = Db(env['MONGO_CONN_URL']!);
  await db.open();
  var deviceCollection = db.collection(DEVICE_COLLECTION);
  var readingCollection = db.collection(READING_COLLECTION);

  server.listen((HttpRequest request) {
    request.response.write("Hello world!");
    request.response.close();
  });
}
