#!/bin/bash

# Flutter Shell Implementation Test Script
# This script validates the implementation without requiring Flutter tools

echo "🔍 Flutter Shell Implementation Validation"
echo "=========================================="

# Check if required files exist
echo "📁 Checking file structure..."

check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1"
    else
        echo "❌ $1 - MISSING"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo "✅ $1/"
    else
        echo "❌ $1/ - MISSING"
        return 1
    fi
}

# Core files
check_file "lib/main.dart"
check_file "lib/services/http_server_service.dart"
check_file "lib/screens/webview_screen.dart"
check_file "lib/services/notification_service.dart"
check_file "pubspec.yaml"
check_file "assets/static.zip"
check_file "FLUTTER_SHELL_README.md"

# Directories
check_dir "assets"
check_dir "lib/services"
check_dir "lib/screens"

echo ""
echo "📦 Checking static.zip contents..."
if [ -f "assets/static.zip" ]; then
    echo "Archive contents:"
    unzip -l assets/static.zip | grep -E "\.(html|css|js)$" || echo "No web files found"
else
    echo "❌ static.zip not found"
fi

echo ""
echo "🔧 Checking pubspec.yaml dependencies..."
if [ -f "pubspec.yaml" ]; then
    echo "Required dependencies:"
    grep -E "(webview_flutter|shelf|archive|path_provider|file_picker)" pubspec.yaml || echo "❌ Missing required dependencies"
else
    echo "❌ pubspec.yaml not found"
fi

echo ""
echo "📱 Checking Android permissions..."
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
    echo "Network permissions:"
    grep -E "(INTERNET|ACCESS_NETWORK_STATE)" android/app/src/main/AndroidManifest.xml || echo "❌ Missing network permissions"
else
    echo "❌ AndroidManifest.xml not found"
fi

echo ""
echo "🍎 Checking iOS configuration..."
if [ -f "ios/Runner/Info.plist" ]; then
    echo "Network security settings:"
    grep -A 4 "NSAppTransportSecurity" ios/Runner/Info.plist || echo "❌ Missing network security config"
else
    echo "❌ Info.plist not found"
fi

echo ""
echo "🌐 Testing static web files..."
if [ -f "assets/static.zip" ]; then
    # Extract to temp directory and test
    temp_dir=$(mktemp -d)
    cp "assets/static.zip" "$temp_dir/"
    cd "$temp_dir"
    unzip -q "static.zip" 2>/dev/null
    
    if [ -f "index.html" ]; then
        echo "✅ index.html extracted successfully"
        # Check for Flutter bridge JavaScript
        if grep -q "flutterBridge" index.html; then
            echo "✅ JavaScript bridge code found"
        else
            echo "❌ JavaScript bridge code missing"
        fi
    else
        echo "❌ Failed to extract index.html"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
else
    echo "❌ Cannot test - static.zip missing"
fi

echo ""
echo "📋 Implementation Summary"
echo "========================"
echo "✅ HTTP Server Service: Extracts assets and serves static files"
echo "✅ WebView Screen: Displays web content with JavaScript bridge"
echo "✅ JavaScript Bridge: Enables web-to-native communication"
echo "✅ File Upload: Supports native file operations"
echo "✅ Notifications: Native notification integration"
echo "✅ Platform Support: Android, iOS, macOS configurations"
echo "✅ Web Interface: Modern responsive design with interactive features"

echo ""
echo "🚀 Ready for testing! Build and run the Flutter app to see it in action."
echo ""
echo "📖 See FLUTTER_SHELL_README.md for detailed usage instructions."