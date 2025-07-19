/*
 * Copyright 2015 Blanyal D'Souza.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:remindly/screens/webview_screen.dart';
import 'package:remindly/services/notification_service.dart';
import 'package:remindly/services/http_server_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.instance.initialize();
  
  runApp(const RemindlyShellApp());
}

class RemindlyShellApp extends StatelessWidget {
  const RemindlyShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Shell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),
      home: const ShellInitScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ShellInitScreen extends StatefulWidget {
  const ShellInitScreen({super.key});

  @override
  State<ShellInitScreen> createState() => _ShellInitScreenState();
}

class _ShellInitScreenState extends State<ShellInitScreen> {
  bool _isInitializing = true;
  String? _serverUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeShell();
  }

  Future<void> _initializeShell() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      // Start HTTP server (this will extract static files and start server)
      await HttpServerService().startServer();
      
      // Get server URL
      final serverUrl = HttpServerService().serverUrl;
      
      if (serverUrl == null) {
        throw Exception('Failed to get server URL');
      }

      setState(() {
        _serverUrl = serverUrl;
        _isInitializing = false;
      });

      // Navigate to WebView screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(serverUrl: serverUrl),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    // Clean up server when app is disposed
    HttpServerService().stopServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.web,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Flutter Shell',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              if (_isInitializing) ...[
                const CircularProgressIndicator(
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Initializing...\nExtracting assets and starting server',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                const Icon(
                  Icons.error,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Initialization Failed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _initializeShell,
                  child: const Text('Retry'),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle,
                  size: 60,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                Text(
                  'Server started at:\n$_serverUrl',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}