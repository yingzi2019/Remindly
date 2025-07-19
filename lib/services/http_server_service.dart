/*
 * HTTP Server Service for serving static files extracted from assets
 */

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class HttpServerService {
  static final HttpServerService _instance = HttpServerService._internal();
  factory HttpServerService() => _instance;
  HttpServerService._internal();

  HttpServer? _server;
  String? _serverUrl;
  String? _staticDir;

  /// Get the server URL
  String? get serverUrl => _serverUrl;

  /// Initialize and start the HTTP server
  Future<void> startServer() async {
    try {
      // Extract static files first
      await _extractStaticFiles();
      
      if (_staticDir == null) {
        throw Exception('Failed to extract static files');
      }

      // Create handler for static files
      final handler = createStaticHandler(
        _staticDir!,
        defaultDocument: 'index.html',
        listDirectories: false,
      );

      // Add CORS headers and logging
      final pipeline = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(handler);

      // Start server on localhost with random available port
      _server = await shelf_io.serve(
        pipeline,
        InternetAddress.loopbackIPv4,
        0, // Use 0 to get any available port
      );

      _serverUrl = 'http://${_server!.address.host}:${_server!.port}';
      
      print('HTTP Server started at: $_serverUrl');
    } catch (e) {
      print('Failed to start HTTP server: $e');
      rethrow;
    }
  }

  /// Stop the HTTP server
  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      _serverUrl = null;
      print('HTTP Server stopped');
    }
  }

  /// Extract static.zip from assets to local directory
  Future<void> _extractStaticFiles() async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      _staticDir = path.join(appDir.path, 'static_web');
      
      final staticDirectory = Directory(_staticDir!);
      
      // Clean up existing directory
      if (await staticDirectory.exists()) {
        await staticDirectory.delete(recursive: true);
      }
      
      // Create directory
      await staticDirectory.create(recursive: true);

      // Load the zip file from assets
      final zipData = await rootBundle.load('assets/static.zip');
      final bytes = zipData.buffer.asUint8List();

      // Extract the archive
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        final filename = file.name;
        final filePath = path.join(_staticDir!, filename);
        
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(filePath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
          print('Extracted: $filename');
        } else {
          // Create directory
          await Directory(filePath).create(recursive: true);
        }
      }
      
      print('Static files extracted to: $_staticDir');
    } catch (e) {
      print('Failed to extract static files: $e');
      rethrow;
    }
  }

  /// Middleware to add CORS headers
  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final response = await innerHandler(request);
        
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
          ...response.headers,
        });
      };
    };
  }

  /// Save uploaded file to device storage
  Future<String> saveUploadedFile(String filename, String base64Content) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final uploadsDir = Directory(path.join(appDir.path, 'uploads'));
      
      if (!await uploadsDir.exists()) {
        await uploadsDir.create(recursive: true);
      }
      
      final file = File(path.join(uploadsDir.path, filename));
      
      // Decode base64 content to bytes
      final bytes = base64Decode(base64Content);
      await file.writeAsBytes(bytes);
      
      return file.path;
    } catch (e) {
      print('Failed to save uploaded file: $e');
      rethrow;
    }
  }
}