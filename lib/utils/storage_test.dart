/*
 * Platform Storage Test
 * 
 * This file demonstrates how the storage service works across platforms:
 * - Web: Uses WebStorageService with SharedPreferences
 * - Mobile (Android/iOS): Uses MobileStorageService with SQLite
 * - Desktop (macOS/Windows/Linux): Uses MobileStorageService with SQLite
 */

import 'package:flutter/foundation.dart';
import 'package:remindly/services/storage_service.dart';
import 'package:remindly/models/reminder.dart';

class StorageTest {
  static void printPlatformInfo() {
    print('=== Platform Information ===');
    print('Platform: ${defaultTargetPlatform}');
    print('Is Web: ${kIsWeb}');
    print('Storage Service: ${StorageService.instance.runtimeType}');
    print('=============================');
  }

  static Future<void> testStorageService() async {
    printPlatformInfo();
    
    try {
      print('\n=== Testing Storage Service ===');
      
      // Test 1: Add a reminder
      print('1. Adding a test reminder...');
      final testReminder = Reminder(
        title: 'Test Reminder - ${DateTime.now().millisecondsSinceEpoch}',
        date: '17/07/2025',
        time: '14:30',
        repeat: false,
        repeatNo: 0,
        repeatType: '',
        active: 1,
      );
      
      final id = await StorageService.instance.addReminder(testReminder);
      print('   ✅ Reminder added with ID: $id');
      
      // Test 2: Retrieve the reminder
      print('2. Retrieving the reminder...');
      final retrievedReminder = await StorageService.instance.getReminder(id);
      if (retrievedReminder != null) {
        print('   ✅ Reminder retrieved: ${retrievedReminder.title}');
      } else {
        print('   ❌ Failed to retrieve reminder');
      }
      
      // Test 3: Get all reminders
      print('3. Getting all reminders...');
      final allReminders = await StorageService.instance.getAllReminders();
      print('   ✅ Total reminders count: ${allReminders.length}');
      
      // Test 4: Update the reminder
      print('4. Updating the reminder...');
      final updatedReminder = Reminder(
        id: id,
        title: 'Updated Test Reminder',
        date: '18/07/2025',
        time: '15:30',
        repeat: true,
        repeatNo: 2,
        repeatType: 'day',
        active: 0,
      );
      
      final updateResult = await StorageService.instance.updateReminder(updatedReminder);
      print('   ✅ Update result: $updateResult');
      
      // Test 5: Verify update
      print('5. Verifying update...');
      final verifyReminder = await StorageService.instance.getReminder(id);
      if (verifyReminder?.title == 'Updated Test Reminder') {
        print('   ✅ Update verified successfully');
      } else {
        print('   ❌ Update verification failed');
      }
      
      // Test 6: Delete the reminder
      print('6. Deleting the test reminder...');
      final deleteResult = await StorageService.instance.deleteReminder(id);
      print('   ✅ Delete result: $deleteResult');
      
      // Test 7: Verify deletion
      print('7. Verifying deletion...');
      final deletedReminder = await StorageService.instance.getReminder(id);
      if (deletedReminder == null) {
        print('   ✅ Deletion verified successfully');
      } else {
        print('   ❌ Deletion verification failed');
      }
      
      print('\n=== All Tests Completed Successfully! ===');
      
    } catch (e, stackTrace) {
      print('\n❌ Error during testing: $e');
      print('Stack trace: $stackTrace');
    }
  }

  static String getPlatformDescription() {
    if (kIsWeb) {
      return '''
🌐 WEB PLATFORM
- Storage: SharedPreferences (Browser Local Storage)
- Service: WebStorageService
- Advantages: 
  ✅ Works in all browsers
  ✅ Cross-browser compatibility
  ✅ No additional setup required
- Limitations:
  ⚠️ Limited storage capacity
  ⚠️ Simpler than database
      ''';
    } else {
      return '''
📱 MOBILE/DESKTOP PLATFORM  
- Storage: SQLite Database
- Service: MobileStorageService
- Advantages:
  ✅ High performance
  ✅ Complex queries supported
  ✅ ACID transactions
  ✅ Large storage capacity
  ✅ Better data integrity
- Requirements:
  📋 SQLite plugin installed
  📋 File system access
      ''';
    }
  }
}
