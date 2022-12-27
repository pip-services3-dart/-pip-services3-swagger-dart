import 'package:pip_services3_components/pip_services3_components.dart';
import 'package:pip_services3_commons/pip_services3_commons.dart';

import '../../pip_services3_swagger.dart';

/// Creates Swagger components by their descriptors.
///
/// See [Factory]
/// See [HttpEndpoint]
/// See [HeartbeatRestService]
/// See [StatusRestService]

class DefaultSwaggerFactory extends Factory {
  static final SwaggerServiceDescriptor =
      Descriptor('pip-services', 'swagger-service', '*', '*', '1.0');

  /// Create a new instance of the factory.
  DefaultSwaggerFactory() : super() {
    registerAsType(
        DefaultSwaggerFactory.SwaggerServiceDescriptor, SwaggerService);
  }
}
