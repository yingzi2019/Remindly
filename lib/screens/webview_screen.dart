/*
 * WebView Screen with JavaScript Bridge functionality
 */

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/http_server_service.dart';
import '../services/notification_service.dart';

class WebViewScreen extends StatefulWidget {
  final String serverUrl;

  const WebViewScreen({super.key, required this.serverUrl});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          setState(() {
            _isLoading = true;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
          _setupJavaScriptBridge();
        },
        onWebResourceError: (WebResourceError error) {
          print('WebView error: ${error.description}');
        },
      ))
      ..loadRequest(Uri.parse(widget.serverUrl));
  }

  void _setupJavaScriptBridge() {
    // Add JavaScript channel for communication with web page
    _controller.addJavaScriptChannel(
      'flutterBridge',
      onMessageReceived: (JavaScriptMessage message) {
        _handleJavaScriptMessage(message.message);
      },
    );

    // Inject bridge object into web page
    _controller.runJavaScript('''
      window.flutterBridge = {
        postMessage: function(message) {
          window.flutterBridge.postMessage(message);
        }
      };
    ''');
  }

  void _handleJavaScriptMessage(String message) async {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final action = data['action'] as String;

      switch (action) {
        case 'native_function':
          await _handleNativeFunction(data['data']);
          break;
        case 'show_notification':
          await _handleShowNotification(data['data']);
          break;
        case 'upload_file':
          await _handleFileUpload(data['data']);
          break;
        case 'get_device_info':
          await _handleGetDeviceInfo();
          break;
        default:
          print('Unknown action: $action');
      }
    } catch (e) {
      print('Error handling JavaScript message: $e');
      _sendMessageToWeb({
        'action': 'error',
        'message': e.toString(),
      });
    }
  }

  Future<void> _handleNativeFunction(dynamic data) async {
    print('Native function called with data: $data');
    
    // Show a native dialog as an example
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Native Function Called'),
          content: Text('Data received: $data'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleShowNotification(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? 'Message from web';

    await NotificationService.instance.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
    );
  }

  Future<void> _handleFileUpload(Map<String, dynamic> data) async {
    try {
      final filename = data['name'] as String;
      final base64Content = data['content'] as String;
      
      final savedPath = await HttpServerService().saveUploadedFile(
        filename,
        base64Content,
      );
      
      _sendMessageToWeb({
        'action': 'file_uploaded',
        'filename': filename,
        'path': savedPath,
      });
    } catch (e) {
      _sendMessageToWeb({
        'action': 'error',
        'message': 'Failed to upload file: $e',
      });
    }
  }

  Future<void> _handleGetDeviceInfo() async {
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;
    
    _sendMessageToWeb({
      'action': 'device_info',
      'platform': platform,
      'version': version,
    });
  }

  void _sendMessageToWeb(Map<String, dynamic> data) {
    final message = jsonEncode(data);
    _controller.runJavaScript('''
      window.dispatchEvent(new CustomEvent('flutter-message', {
        detail: '$message'
      }));
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Shell'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: _pickAndUploadFile,
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showServerInfo,
        child: const Icon(Icons.info),
      ),
    );
  }

  void _showServerInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server URL: ${widget.serverUrl}'),
            const SizedBox(height: 8),
            const Text('Features:'),
            const Text('• Static file serving'),
            const Text('• JavaScript bridge'),
            const Text('• File upload support'),
            const Text('• Native notifications'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        
        if (bytes != null) {
          final base64Content = base64Encode(bytes);
          
          _sendMessageToWeb({
            'action': 'file_selected',
            'name': file.name,
            'size': file.size,
            'content': base64Content,
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('File ${file.name} selected')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }
}