# Flutter Shell - HTTPS Service Implementation

This Flutter app has been transformed into a shell that serves web content locally with native bridge functionality.

## Features

### 🚀 Core Functionality
- **Asset Extraction**: Automatically extracts `assets/static.zip` to local directory on startup
- **HTTP Server**: Starts local HTTP server to host extracted static files
- **WebView Integration**: Displays web content from local server
- **JavaScript Bridge**: Enables web pages to call native Flutter functions
- **File Operations**: Supports file upload and other native functionality

### 🌐 Web Interface
The included web application (`assets/static.zip`) provides:
- Modern responsive design with gradient background
- Interactive buttons to test native functions
- File upload capability with progress feedback
- Device information display
- Notification testing

### 🔧 JavaScript Bridge API

The bridge provides the following methods for web pages:

```javascript
// Call native function
window.flutterBridge.postMessage(JSON.stringify({
    action: 'native_function',
    data: 'Hello from Web!'
}));

// Show native notification
window.flutterBridge.postMessage(JSON.stringify({
    action: 'show_notification',
    data: {
        title: 'Web Notification',
        body: 'Message from web page'
    }
}));

// Upload file (base64 content)
window.flutterBridge.postMessage(JSON.stringify({
    action: 'upload_file',
    data: {
        name: 'filename.txt',
        size: 1234,
        type: 'text/plain',
        content: 'base64_encoded_content'
    }
}));

// Get device information
window.flutterBridge.postMessage(JSON.stringify({
    action: 'get_device_info'
}));
```

### 📱 Platform Support
- **Android**: Full support with network permissions
- **iOS**: Full support with localhost network access
- **macOS**: Supported
- **Web**: Limited (no file access)

## Architecture

### Key Components

1. **HttpServerService** (`lib/services/http_server_service.dart`)
   - Extracts static.zip from assets
   - Starts Shelf HTTP server on random available port
   - Serves static files with CORS headers
   - Handles file uploads to device storage

2. **WebViewScreen** (`lib/screens/webview_screen.dart`)
   - Displays web content in WebView
   - Implements JavaScript bridge for native communication
   - Handles file picker integration
   - Shows server information

3. **ShellInitScreen** (`lib/main.dart`)
   - Initializes notification service
   - Starts HTTP server
   - Shows loading/error states
   - Navigates to WebView when ready

### File Structure
```
lib/
├── main.dart                     # App entry point and initialization
├── screens/
│   └── webview_screen.dart      # WebView with JavaScript bridge
└── services/
    ├── http_server_service.dart # HTTP server and file extraction
    └── notification_service.dart # Native notifications

assets/
└── static.zip                  # Web application files
    ├── index.html              # Main web interface
    └── style.css              # Additional styles
```

## Usage

1. **Build and run** the Flutter app
2. **Wait for initialization** (extracts assets and starts server)
3. **Interact with web interface** through the WebView
4. **Test native functions** using the provided buttons
5. **Upload files** using the file picker or web interface

## Development

### Adding New Native Functions

To add a new native function accessible from JavaScript:

1. Add a new case to `_handleJavaScriptMessage()` in `WebViewScreen`
2. Implement the function logic
3. Update the web interface to call the new function

### Modifying Web Content

1. Update files in `/tmp/static_content/`
2. Create new `static.zip`: `cd /tmp/static_content && zip -r ../static.zip .`
3. Replace `assets/static.zip` with the new file

### Server Configuration

The HTTP server:
- Binds to `localhost` (127.0.0.1)
- Uses random available port (typically 8000+)
- Serves files from extracted static directory
- Includes CORS headers for cross-origin requests

## Security Considerations

- Server only binds to localhost (not accessible externally)
- File uploads are stored in app's documents directory
- Web content is sandboxed within WebView
- Native function access is controlled through JavaScript bridge

## Troubleshooting

### Common Issues

1. **"Flutter bridge not available"**
   - Ensure WebView has fully loaded
   - Check JavaScript console for errors

2. **File upload fails**
   - Check device storage permissions
   - Verify file size limits

3. **Server won't start**
   - Check for port conflicts
   - Verify asset extraction succeeded

4. **Notifications don't appear**
   - Check app notification permissions
   - Test on physical device (notifications may not work in simulator)

### Debug Information

The app logs detailed information to console:
- Server startup and URL
- Asset extraction progress
- JavaScript bridge communications
- File upload status
- Notification scheduling

Use `flutter logs` or platform-specific debugging tools to view console output.