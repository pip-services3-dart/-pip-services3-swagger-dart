import 'dart:async';
import 'dart:io';

import 'package:pip_services3_commons/pip_services3_commons.dart';
import 'package:pip_services3_components/pip_services3_components.dart';
import 'package:pip_services3_rpc/pip_services3_rpc.dart';
import 'package:pip_services3_swagger/pip_services3_swagger.dart';

import 'logic/DummyController.dart';
import 'services/DummyCommandableHttpService.dart';
import 'services/DummyRestService.dart';

void main(List<String> args) async {
  // Create components
  var logger = ConsoleLogger();
  var controller = DummyController();
  var httpEndpoint = HttpEndpoint();
  var restService = DummyRestService();
  var httpService = DummyCommandableHttpService();
  var statusService = StatusRestService();
  var heartbeatService = HeartbeatRestService();
  var swaggerService = SwaggerService();

  var components = [
    controller,
    httpEndpoint,
    restService,
    httpService,
    statusService,
    heartbeatService,
    swaggerService
  ];

  // Configure components
  logger.configure(ConfigParams.fromTuples(['level', 'trace']));

  httpEndpoint.configure(ConfigParams.fromTuples([
    'connection.protocol',
    'http',
    'connection.host',
    'localhost',
    'connection.port',
    8080
  ]));

  restService.configure(ConfigParams.fromTuples(['swagger.enable', true]));

  httpService.configure(ConfigParams.fromTuples(
      ['base_route', 'dummies2', 'swagger.enable', true]));

  try {
    // Set references
    var references = References.fromTuples([
      Descriptor('pip-services', 'logger', 'console', 'default', '1.0'),
      logger,
      Descriptor('pip-services', 'counters', 'log', 'default', '1.0'),
      LogCounters(),
      Descriptor('pip-services', 'endpoint', 'http', 'default', '1.0'),
      httpEndpoint,
      Descriptor(
          'pip-services-dummies', 'controller', 'default', 'default', '1.0'),
      controller,
      Descriptor('pip-services-dummies', 'service', 'rest', 'default', '1.0'),
      restService,
      Descriptor('pip-services-dummies', 'service', 'commandable-http',
          'default', '1.0'),
      httpService,
      Descriptor('pip-services', 'status-service', 'rest', 'default', '1.0'),
      statusService,
      Descriptor('pip-services', 'heartbeat-service', 'rest', 'default', '1.0'),
      heartbeatService,
      Descriptor('pip-services', 'swagger-service', 'http', 'default', '1.0'),
      swaggerService
    ]);

    Referencer.setReferences(references, components);

    // Open components
    await Opener.open(null, components);

    print('Press Ctrl-C to stop the microservice...');

    // Wait until user presses ENTER
    var keyPresed = false;

    stdin.listen((List<int> event) {
      keyPresed = true;
    });

    while (!keyPresed) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    await Closer.close(null, components);

    exit(0);
  } catch (ex) {
    logger.error(null, ex as Exception, 'Failed to execute the microservice');
    exit(1);
  }
}
