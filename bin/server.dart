import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

void main() async {
  // Get port from environment variable, defaulting to 5000
  final port = int.parse(Platform.environment['PORT'] ?? '5000');
  
  // Create a handler for static files (serve from build/web directory)
  final staticHandler = createStaticHandler(
    'build/web',
    defaultDocument: 'index.html',
    listDirectories: false,
  );
  
  // Create a proper SPA fallback handler for Flutter web
  Handler spaFallbackHandler = (request) {
    // For missing routes in a Flutter web app, serve index.html
    if (request.method == 'GET') {
      final acceptHeader = request.headers['accept'] ?? '';
      if (acceptHeader.contains('text/html')) {
        // Read and serve the actual Flutter web index.html
        final indexFile = File('build/web/index.html');
        if (indexFile.existsSync()) {
          return Response.ok(
            indexFile.readAsStringSync(),
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }
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