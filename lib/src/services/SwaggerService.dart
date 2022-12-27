import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:pip_services3_rpc/pip_services3_rpc.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SwaggerService extends RestService implements ISwaggerService {
  final Map _routes = {};

  SwaggerService() : super() {
    baseRoute = 'swagger';
  }

  Future<Uri> _resolveUri(Uri uri) async {
    if (uri.scheme == 'package') {
      return Isolate.resolvePackageUri(uri).then((resolvedUri) {
        if (resolvedUri == null) {
          throw ArgumentError.value(uri, 'uri', 'Unknown package');
        }

        return resolvedUri;
      });
    }
    var resolvedUri = Uri.base.resolveUri(uri);
    return resolvedUri;
  }

  Future<Uri> _calculateFileUri(String fileName) async {
    var packageUri =
        Uri.parse('package:pip_services3_swagger/src/swagger-ui/' + fileName);
    var fileUri = await _resolveUri(packageUri);

    return fileUri;
  }

  String _calculateContentType(String fileName) {
    var ext = fileName.split('.').last;
    switch (ext) {
      case 'html':
        return 'text/html';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';
      case 'png':
        return 'image/png';
      default:
        return 'text/plain';
    }
  }

  Future<bool> _checkFileExist(String? fileName) async {
    if (fileName == null) {
      return false;
    }
    var uri = await _calculateFileUri(fileName);
    return File.fromUri(uri).existsSync();
  }

  Future _loadFileContent(String fileName) async {
    var uri = await _calculateFileUri(fileName);

    if (fileName.split('.').last == 'png') {
      return File.fromUri(uri).readAsBytesSync().toList();
    }

    return File.fromUri(uri).readAsStringSync();
  }

  FutureOr<Response> _getSwaggerFile(Request req) async {
    var fileName = req.params['file_name']?.toLowerCase();

    if (!await _checkFileExist(fileName)) {
      return Response.notFound(null);
    }

    return Response(200,
        headers: {'Content-Type': _calculateContentType(fileName!)},
        body: await _loadFileContent(fileName));
  }

  FutureOr<Response> _getIndex(Request req) async {
    var content = await _loadFileContent('index.html');

    // Inject urls
    var urls = <Map>[];
    for (var prop in _routes.keys) {
      var url = {'name': prop, 'url': _routes[prop]};
      urls.add(url);
    }
    content = content.replaceAll('[/*urls*/]', json.encode(urls));

    return Response.ok(content, headers: {'Content-Type': 'text/html'});
  }

  FutureOr<Response> _redirectToIndex(Request req) async {
    var url = req.url.toString();
    if (!url.endsWith('/')) url = url + '/';
    return Response(302, headers: {'location': url + 'index.html'});
  }

  String _composeSwaggerRoute(String? baseRoute, String? route) {
    if (baseRoute != null && baseRoute != '') {
      if (route == null || route == '') route = '/';
      if (!route.startsWith('/')) route = '/' + route;
      if (!baseRoute.startsWith('/')) baseRoute = '/' + baseRoute;
      route = baseRoute + route;
    }

    return route ?? '';
  }

  @override
  void registerOpenApiSpec(String? baseRoute, String? swaggerRoute) {
    if (swaggerRoute == null) {
      super.registerOpenApiSpec_(baseRoute!);
    } else {
      var route = _composeSwaggerRoute(baseRoute, swaggerRoute);
      baseRoute = baseRoute ?? 'default';
      _routes[baseRoute] = route;
    }
  }

  @override
  void register() {
    // A hack to redirect default base route
    var baseRoute = this.baseRoute;
    this.baseRoute = null;

    registerRoute('get', baseRoute!, null, _redirectToIndex);
    this.baseRoute = baseRoute;

    registerRoute('get', '/', null, _redirectToIndex);

    registerRoute('get', '/index.html', null, _getIndex);

    registerRoute('get', '/<file_name>', null, _getSwaggerFile);
  }
}
