import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

void main() async {
  // Get port from environment variable, defaulting to 5000
  final port = int.parse(Platform.environment['PORT'] ?? '5000');
  
  // Create a handler for static files
  final staticHandler = createStaticHandler(
    'build/web',
    defaultDocument: 'index.html',
    listDirectories: false,
  );
  
  // Pre-load index.html for efficiency
  final indexHtml = File('build/web/index.html').readAsStringSync();
  
  // Create a proper SPA fallback handler that only serves index.html for HTML requests
  Handler spaFallbackHandler = (request) {
    // Only serve index.html for GET requests that accept HTML
    if (request.method == 'GET') {
      final acceptHeader = request.headers['accept'] ?? '';
      if (acceptHeader.contains('text/html')) {
        return Response.ok(
          indexHtml,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }
    }
    // Return 404 for non-HTML requests and missing assets
    return Response.notFound('Not Found');
  };
  
  // Create a cascade handler
  final cascadeHandler = Cascade()
    .add(staticHandler)
    .add(spaFallbackHandler)
    .handler;
  
  // Add basic middleware
  final handler = Pipeline()
    .addMiddleware(logRequests())
    .addHandler(cascadeHandler);
  
  // Start the server
  final server = await shelf_io.serve(
    handler,
    '0.0.0.0',
    port,
  );
  
  print('Server running on http://${server.address.host}:${server.port}');
}