import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import '../lib/utils/constants.dart';

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

server.listen((HttpRequest request) async {
  if (request.uri.path == "/") {
    request.response.headers.add("Access-Control-Allow-Origin", "*");
    request.response.headers.add("Access-Control-Allow-Headers", "*");
    request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
    request.response.statusCode = HttpStatus.OK;
    request.response.write("Plantwatch API");
    request.response.close();
  } else if (request.uri.path == "/devices" && request.method == 'GET') {
    request.response.headers.add("Access-Control-Allow-Origin", "*");
    request.response.headers.add("Access-Control-Allow-Headers", "*");
    request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
    request.response.statusCode = HttpStatus.OK;
    request.response.write(json.encode(await deviceCollection.find().toList()));
    request.response.close();
    } else if (request.uri.path.startsWith("/devices") && request.method == 'OPTIONS') {
      // This is required so that this route will work without disabling CORS/web security on the frontend application
        request.response.headers.add("Access-Control-Allow-Origin", "*");
        request.response.headers.add("Access-Control-Allow-Headers", "*");
        request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
        request.response.statusCode = HttpStatus.OK;
        request.response.close();
    } else if (request.uri.path.startsWith("/devices") && request.method == 'PUT' && request.uri.pathSegments.length == 2) {
        var deviceId = request.uri.pathSegments[1];
        var device = await deviceCollection.findOne(where.eq("_id", deviceId));
        var content = await utf8.decoder.bind(request).join();
        var parameters = json.decode(content);
        device!["parameters"] = parameters;
        await deviceCollection.save(device);
        request.response.headers.add("Access-Control-Allow-Origin", "*");
        request.response.headers.add("Access-Control-Allow-Headers", "*");
        request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(json.encode(device));
        request.response.close();
  } else if (request.uri.path.startsWith("/readings") && request.method == 'GET'){
      if (request.uri.pathSegments.length == 1) {
        request.response.headers.add("Access-Control-Allow-Origin", "*");
        request.response.headers.add("Access-Control-Allow-Headers", "*");
        request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
        request.response.statusCode = HttpStatus.OK;
        request.response.write(json.encode(await readingCollection.find().toList()));
        request.response.close();
      } else if (request.uri.pathSegments.length == 2){
        request.response.headers.add("Access-Control-Allow-Origin", "*");
        request.response.headers.add("Access-Control-Allow-Headers", "*");
        request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
        request.response.write(await json.encode(await readingCollection.findOne(where.eq("_id", request.uri.pathSegments[1]))));
        request.response.close();
      }
  } else {
    request.response.headers.add("Access-Control-Allow-Origin", "*");
    request.response.headers.add("Access-Control-Allow-Headers", "*");
    request.response.headers.add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
    request.response.statusCode = HttpStatus.badRequest;
    request.response.write("Bad request");
    request.response.close();
  }
});
}
