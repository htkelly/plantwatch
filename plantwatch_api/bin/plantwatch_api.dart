import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import '../lib/utils/constants.dart';
import 'package:firebase_admin/firebase_admin.dart';

main(List<String> arguments) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  var env = DotEnv(includePlatformEnvironment: true)..load();
  var fb = FirebaseAdmin.instance.initializeApp(AppOptions(
    credential: FirebaseAdmin.instance.certFromPath('../service-account.json'),
  ));
  int port = 8085;
  var server = await HttpServer.bind(env['API_SERVER_IP'], port);
  Db db = Db(env['MONGO_CONN_URL']!);
  await db.open();
  var deviceCollection = db.collection(DEVICE_COLLECTION);
  var readingCollection = db.collection(READING_COLLECTION);

  server.listen((HttpRequest request) async {
    request.response.headers.add("Access-Control-Allow-Origin", "*");
    request.response.headers.add("Access-Control-Allow-Headers", "*");
    request.response.headers
        .add("Access-Control-Allow-Methods", "POST,GET,DELETE,PUT,OPTIONS");
    if (request.uri.path == "/") {
      request.response.statusCode = HttpStatus.OK;
      request.response.write("Hello! This is the Plantwatch API");
      request.response.close();
      // This handler gets devices associated with the logged in user's account
    } else if (request.uri.path == "/devices" && request.method == 'GET') {
      try {
        var auth = request.headers['Authorization'];
        if (auth == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        var token = await fb.auth().verifyIdToken(auth![0].split(' ')[1]);
        if (token == null ||
            token.claims == null ||
            token.claims.subject == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        } else {
          var devices = await deviceCollection
              .find(where.eq("userId", token.claims.subject))
              .toList();
          request.response.statusCode = HttpStatus.OK;
          request.response.write(json.encode(devices));
          request.response.close();
        }
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal Server Error');
        request.response.close();
      }
      // This handler is required so that this route will work without disabling CORS/web security on the frontend application
    } else if ((request.uri.path.startsWith("/devices") ||
        request.uri.path.startsWith("/readings")) &&
            request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.OK;
      request.response.close();
      // This handler sets parameters on a device
    } else if (request.uri.path.startsWith("/devices") &&
        request.method == 'PUT' &&
        request.uri.pathSegments.length == 2) {
      try {
        var deviceId = request.uri.pathSegments[1];
        var auth = request.headers['Authorization'];
        if (auth == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        var token = await fb.auth().verifyIdToken(auth![0].split(' ')[1]);
        var device = await deviceCollection.findOne(where.eq("_id", deviceId));
        if (device == null) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Device not found');
          request.response.close();
          return;
        }
        if (token == null ||
            token.claims == null ||
            device['userId'] != token.claims.subject) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        var content = await utf8.decoder.bind(request).join();
        var parameters = json.decode(content);
        device["parameters"] = parameters;
        await deviceCollection.save(device);
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(json.encode(device));
        request.response.close();
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal Server Error');
        request.response.close();
      }
      // This handler associates a device with a user account
    } else if (request.uri.path.startsWith("/devices") &&
        request.method == 'PUT' &&
        request.uri.pathSegments.length == 3 &&
        request.uri.pathSegments[2] == 'user') {
      try {
        var deviceId = request.uri.pathSegments[1];
        var auth = request.headers['Authorization'];
        if (auth == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        var token = await fb.auth().verifyIdToken(auth![0].split(' ')[1]);
        if (token == null ||
            token.claims == null ||
            token.claims.subject == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        var device = await deviceCollection.findOne(where.eq("_id", deviceId));
        device!["userId"] = token.claims.subject;
        await deviceCollection.save(device);
        request.response.statusCode = HttpStatus.accepted;
        request.response.write(json.encode(device));
        request.response.close();
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal server error');
        request.response.close();
      }
      // This handler returns readings associated with a device
    } else if (request.uri.path.startsWith("/devices") &&
        request.method == 'GET' &&
        request.uri.pathSegments.length == 3 &&
        request.uri.pathSegments[2] == 'readings') {
      try {
        var deviceId = request.uri.pathSegments[1];
        var device = await deviceCollection.findOne(where.eq("_id", deviceId));
        var auth = request.headers['Authorization'];
        if (auth == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        var token = await fb.auth().verifyIdToken(auth![0].split(' ')[1]);
        if (device == null) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Device not found');
          request.response.close();
          return;
        }
        if (token == null ||
            token.claims == null ||
            device['userId'] != token.claims.subject) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        request.response.statusCode = HttpStatus.OK;
        request.response.write(await json.encode(await readingCollection
            .find(where.eq("deviceId", deviceId))
            .toList()));
        request.response.close();
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal server error');
        request.response.close();
      }
      // This handler gets a reading by id
    } else if (request.uri.path.startsWith("/readings") &&
        request.method == 'GET' &&
        request.uri.pathSegments.length == 2) {
      try {
        var reading = await readingCollection
            .findOne(where.eq("_id", request.uri.pathSegments[1]));
        if (reading == null) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Reading not found');
          request.response.close();
          return;
        }
        var device = await deviceCollection
            .findOne(where.eq("_id", reading['deviceId']));
        if (device == null) {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Device not found');
          request.response.close();
          return;
        }
        var auth = request.headers['Authorization'];
        if (auth == null) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        var token = await fb.auth().verifyIdToken(auth![0].split(' ')[1]);
        if (token == null ||
            token.claims == null ||
            device['userId'] != token.claims.subject) {
          request.response.statusCode = HttpStatus.unauthorized;
          request.response.write('Unauthorized');
          request.response.close();
          return;
        }
        request.response.statusCode = HttpStatus.OK;
        request.response.write(await json.encode(reading));
        request.response.close();
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Internal server error');
        request.response.close();
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write("Route not found");
      request.response.close();
    }
  });
}
