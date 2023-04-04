# Plantwatch

## What's this?
Plantwatch is an IoT plant health monitoring and care system that utilises electronic sensors and a Raspberry Pi to collect data on soil moisture, temperature, humidity, and light intensity. A backend service communicates with the Raspberry Pi via RabbitMQ, logs sensor data to a MongoDB database, and sends control data back to the Raspberry Pi, which can also operate actuators for environmental control. A web and mobile application allows the end user to add devices to their account, view sensor data, and set desired parameters. Flutter provides the frontend and interfaces with MongoDB via a REST API implemented in Dart.

## Got a demo?
Demo video will go here when complete.

## What do I need to deploy it?

### Sensor Device
- Raspberry Pi 4 model B running Raspbian and with the following
    - Python 3.x
    - pika library (https://pika.readthedocs.io/en/stable/)
    - gpiozero library (https://gpiozero.readthedocs.io/en/stable/)
    - protobuf library (https://pypi.org/project/protobuf/)
    - grove.py library (https://github.com/Seeed-Studio/grove.py)
- Seeed Studio Grove Base Hat for Raspberry Pi
- Seeed Studio Grove sensors including:
    - Temperature and Humidity sensor
    - Moisture sensor
    - Sunlight sensor
- 12v water pump
- Seeed Studio Grove Relay
- LEDs and resistors
- Before running plantwatch_sensor.py, you'll need to configure a .env file with the hostname and credentials for RabbitMQ access

### Infrastructure
- A linux server (Debian recommended) for each of the following
    - RabbitMQ
        - Installation guide here: https://www.rabbitmq.com/install-debian.html
        - You'll need to configure a non-default user account, which both the sensor device and the worker service will use to authenticate
    - MongoDB
        - Installation guide here: https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-debian/
        - You'll need to edit /etc/mongod.conf to bind to the server IP address
    - Plantwatch worker service
        - You'll need Python 3.x on this server, and these libraries:
            - https://pymongo.readthedocs.io/en/stable/
            - https://pika.readthedocs.io/en/stable/
            - https://pypi.org/project/protobuf/
        - You'll need to configure a .env file with RabbitMQ credentials, and hostnames or IP addresses for the MongoDB and RabbitMQ servers
    - Plantwatch API service
        - You'll need the Dart runtime on this server, and this library:
            - https://pub.dev/packages/firebase_admin
        - You'll need to configure a .env file with the IP address the API service should bind to, and a hostname or IP address for the MongoDB server
        - You'll need to configure a service-account.json file with a private key for a Firebase service account, which the API will use for JWT validation
- A Firebase project to handle user authentication
- Somewhere to host the frontend application (Firebase Hosting recommended)

### Networking requirements
When configuring networking for the project infrastructure, bear in mind the following
- RabbitMQ must be able to receive AMQP connections on TCP port 5671 from the outside world and from the worker service
- MongoDB must be able to receive connections on TCP port 27017 from the worker service and from the REST API service, but should not be reachable from the outside world
- The worker service must be able make connections to RabbitMQ on TCP port 5671 and MongoDB on TCP port 27017, but does not need to contact the outside world
- The REST API service must be able to receive http connections on TCP port 8085 from the outside world and must be able to reach MongoDB on TCP port 27017

### What resources did you consult to build this?
Here's a list of things I found useful while building this project:

- https://www.python-engineer.com/posts/dotenv-python/
- https://raspberrypi.stackexchange.com/questions/133457/how-can-rpi4b-use-python-to-talk-to-the-i2c-dht20-sht20-temperature-and-humidi
- https://www.rabbitmq.com/tutorials/tutorial-one-python.html
- https://stackoverflow.com/questions/53351186/publish-to-rabbitmq-queue-with-http-api
- https://stackoverflow.com/questions/29575789/rabbitmq-queue-messages-before-writing-to-mongodb
- https://levelup.gitconnected.com/mongodb-with-flutter-407de79f84e4
- https://pika.readthedocs.io/en/stable/modules/channel.html
- https://pika.readthedocs.io/en/stable/examples/blocking_basic_get.html
- https://www.rabbitmq.com/amqp-0-9-1-reference.html#basic.consume
- https://github.com/microsoft/IoT-For-Beginners/issues/287
- https://forum.seeedstudio.com/t/airquality-sensor-on-grove-pi-at-facing-check-whether-i2c-enabled-and-grove-base-hat-rpi-or-grove-base-hat-rpi-zero-inserted/259371/7
- https://stackoverflow.com/questions/60883397/using-pymongo-upsert-to-update-or-create-a-document-in-mongodb-using-python
- https://stackoverflow.com/questions/13710770/how-to-update-values-using-pymongo
- https://medium.com/dlt-labs-publication/how-to-build-a-flutter-card-list-in-less-than-10-minutes-9839f79a6c08
- https://medium.com/swlh/live-templates-flutter-6e48683e14e0
- https://stackoverflow.com/questions/70401732/a-list-of-all-flutter-icons
- https://stackoverflow.com/questions/59924840/how-to-connect-flutter-with-mongodb
- https://www.youtube.com/watch?v=PpYATokJiSE
- https://medium.flutterdevs.com/explore-futurebuilder-in-flutter-9744203b2b8c
- https://fluttercrashcourse.com/blog/05-models
- https://stackoverflow.com/questions/61633504/flutter-how-to-parse-json-mongodb-data
- https://pub.dev/packages/mongo_dart
- https://www.bezkoder.com/dart-object-to-map/
- https://pub.dev/packages/logging
- https://stackoverflow.com/questions/63105464/is-there-any-way-to-iterate-over-futurelist-in-flutter
- https://stackoverflow.com/questions/59924840/how-to-connect-flutter-with-mongodb
- https://levelup.gitconnected.com/mongodb-with-flutter-407de79f84e4
- https://github.com/harshshinde07/MongoDB-Flutter
- https://360techexplorer.com/connect-flutter-to-mongodb/
- https://www.youtube.com/watch?v=ggfjXPX5G6o
- https://www.youtube.com/watch?v=Y5X5rdzFScs
- https://stackoverflow.com/questions/53886304/understanding-factory-constructor-code-example-dart
- https://medium.com/swlh/the-simplest-way-to-pass-and-fetch-data-between-stateful-and-stateless-widgets-pages-full-2021-c5dbce8db1db
- https://www.youtube.com/watch?v=DPcsXG9KVVU
- https://stackoverflow.com/questions/50287995/passing-data-to-statefulwidget-and-accessing-it-in-its-state-in-flutter
- https://stackoverflow.com/questions/53919391/refresh-flutter-text-widget-content-every-5-minutes-or-periodically
- https://docs.flutter.dev/cookbook/navigation/named-routes
- https://www.geeksforgeeks.org/flutter-making-card-clickable/
- https://stackoverflow.com/questions/64484113/the-argument-type-function-cant-be-assigned-to-the-parameter-type-void-funct
- https://pub.dev/packages/flutter_dotenv
- https://pymongo.readthedocs.io/en/stable/tutorial.html
- https://stackoverflow.com/questions/1602934/check-if-a-given-key-already-exists-in-a-dictionary
- https://docs.flutter.dev/cookbook/forms/validation
- https://stackoverflow.com/questions/49577781/how-to-create-number-input-field-in-flutter
- https://stackoverflow.com/questions/61538657/how-to-get-value-from-textformfield-on-flutter
- https://firebase.google.com/codelabs/firebase-auth-in-flutter-apps#0
- https://github.com/dsdenes/hapi-auth-firebase
- https://www.youtube.com/watch?v=UGuTTxH9Gfk
- https://pub.dev/packages/dotenv/example
- https://github.com/flutter/flutter/issues/122892
- https://restfulapi.net/rest-put-vs-post/
- https://github.com/graphicbeacon/dart_mongo/tree/part-2
- https://stackoverflow.com/questions/56956209/utf8-decoder-not-working-after-latest-flutter-upgrade
- https://stackoverflow.com/questions/56956209/utf8-decoder-not-working-after-latest-flutter-upgrade
- https://stackoverflow.com/questions/10456591/cors-with-dart-how-do-i-get-it-to-work
- https://stackoverflow.com/questions/68315277/flutter-http-invalid-arguments-invalid-request-body-when-jsonencode-is-used
- https://firebase.google.com/docs/auth/flutter/start
- https://firebase.google.com/codelabs/firebase-auth-in-flutter-apps#4
- https://firebase.flutter.dev/docs/auth/usage/
- https://firebase.google.com/docs/auth/admin/verify-id-tokens
- https://stackoverflow.com/questions/33265812/best-http-authorization-header-type-for-jwt
- https://github.com/appsup-dart/firebase_admin
- https://firebase.google.com/support/guides/service-accounts
- https://github.com/appsup-dart/firebase_admin/issues/8
- https://api.flutter.dev/flutter/dart-core/String/split.html
- https://stackoverflow.com/questions/49804891/force-flutter-navigator-to-reload-state-when-popping
- https://blog.logrocket.com/build-beautiful-charts-flutter-fl-chart/
- https://github.com/imaNNeo/fl_chart/issues/438
- https://google.github.io/charts/flutter/gallery.html
- https://google.github.io/charts/flutter/example/time_series_charts/simple
- https://www.youtube.com/watch?v=VV6tBQSe-jg
- https://stackoverflow.com/questions/49578529/flutter-filter-list-as-per-some-condition
- https://api.dart.dev/stable/2.19.3/dart-core/DateTime/subtract.html
- https://stackoverflow.com/questions/60133252/what-is-the-purpose-of-a-factory-method-in-flutter-dart
- https://google.github.io/charts/flutter/example/time_series_charts/simple.html
- https://github.com/google/charts
- https://stackoverflow.com/questions/52060516/flutter-how-to-change-android-minsdkversion-in-flutter-project
- https://protobuf.dev/getting-started/pythontutorial/
- https://stackoverflow.com/questions/68056043/convert-serialized-protobuf-output-to-python-dictionary
- https://googleapis.dev/python/protobuf/latest/google/protobuf/json_format.html
- https://stackoverflow.com/questions/19734617/protobuf-to-json-in-python
- https://stackoverflow.com/questions/67687268/converting-python-dict-to-protobuf
- https://stackoverflow.com/questions/47373976/why-is-my-protobuf-message-in-python-ignoring-zero-values