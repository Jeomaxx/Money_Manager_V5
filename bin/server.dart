import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

void main() async {
  // Get port from environment variable, defaulting to 5000
  final port = int.parse(Platform.environment['PORT'] ?? '5000');
  
  // Create a handler for static files (serve from web/ directory instead of build/web)
  final staticHandler = createStaticHandler(
    'web',
    defaultDocument: 'index.html',
    listDirectories: false,
  );
  
  // Create a simple index.html for the expense manager
  final indexHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Expense Manager</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
      background-color: #f5f5f5;
    }
    .container {
      background: white;
      padding: 30px;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    h1 {
      color: #2196F3;
      text-align: center;
    }
    .feature {
      margin: 20px 0;
      padding: 15px;
      background: #f8f9fa;
      border-left: 4px solid #2196F3;
    }
    .status {
      text-align: center;
      padding: 15px;
      background: #4CAF50;
      color: white;
      border-radius: 5px;
      margin: 20px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>💰 Expense Manager</h1>
    <div class="status">✅ Server is running successfully!</div>
    
    <div class="feature">
      <h3>🎯 Features Available</h3>
      <ul>
        <li>Cross-platform expense tracking (iOS, Android, Web, Desktop)</li>
        <li>Voice input for hands-free expense entry</li>
        <li>AI-powered expense categorization using Google Generative AI</li>
        <li>Data visualization with interactive charts</li>
        <li>CSV/Excel export functionality</li>
        <li>Local database storage (Hive + SQLite)</li>
        <li>Multi-language support</li>
      </ul>
    </div>
    
    <div class="feature">
      <h3>🔧 Technical Architecture</h3>
      <ul>
        <li>Flutter frontend for cross-platform UI</li>
        <li>Dart backend server with Shelf framework</li>
        <li>Hive NoSQL database for fast local storage</li>
        <li>SQLite for structured data when needed</li>
        <li>Google Generative AI integration</li>
        <li>PWA capabilities for offline support</li>
      </ul>
    </div>
    
    <div class="feature">
      <h3>📱 Platform Support</h3>
      <ul>
        <li>Web (Progressive Web App)</li>
        <li>iOS (Native app)</li>
        <li>Android (Native app)</li>
        <li>Windows (Desktop app)</li>
        <li>Linux (Desktop app)</li>
        <li>macOS (Desktop app)</li>
      </ul>
    </div>
    
    <p style="text-align: center; color: #666; margin-top: 30px;">
      Ready for GitHub upload and production deployment 🚀
    </p>
  </div>
</body>
</html>
''';
  
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