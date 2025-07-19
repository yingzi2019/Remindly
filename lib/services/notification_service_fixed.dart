/*
 * Copyright 2015 Blanyal D'Souza.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool _isPlatformSupported() {
    // Check if the current platform supports local notifications
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Set local timezone consistently across all platforms
    try {
      final String timeZoneName = 'Asia/Shanghai'; // 统一使用中国时区
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('🌍 Timezone initialized: ${tz.local.name}');
      debugPrint('🕐 Current timezone offset: ${tz.local.currentTimeZone.offset}');
    } catch (e) {
      debugPrint('⚠️ Timezone setup warning: $e');
      // Fallback to system timezone
      debugPrint('🔄 Using system timezone as fallback');
    }

    // Debug current time in different formats
    final now = DateTime.now();
    final nowTZ = tz.TZDateTime.now(tz.local);
    debugPrint('📅 System DateTime.now(): $now');
    debugPrint('🌍 TZDateTime.now(local): $nowTZ');

    // Check if notifications are supported on this platform
    if (!_isPlatformSupported()) {
      debugPrint('Notifications not supported on this platform');
      _initialized = true;
      return;
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );
    
    // Request permissions for iOS
    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      final bool? granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('iOS notification permissions granted: $granted');
      
      if (granted != true) {
        debugPrint('❌ iOS notification permissions denied! Notifications will not work.');
        debugPrint('📱 Please enable notifications in iOS Settings > Remindly > Notifications');
      } else {
        debugPrint('✅ iOS notification permissions successfully granted!');
      }
    }
        
    // Request permissions for macOS
    await _notifications
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    // Request exact alarm permission for Android 12+ (API 31+)
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_initialized) await initialize();

    // Skip scheduling if platform doesn't support notifications
    if (!_isPlatformSupported()) {
      debugPrint('Skipping notification scheduling - platform not supported');
      return;
    }

    final DateTime scheduleTime = _parseDateTime(reminder.date, reminder.time);
    final DateTime now = DateTime.now();
    
    debugPrint('📋 Scheduling reminder: ${reminder.title}');
    debugPrint('⏰ Schedule time: $scheduleTime');
    debugPrint('🕐 Current time: $now');
    debugPrint('⏳ Time difference: ${scheduleTime.difference(now).inMinutes} minutes');
    debugPrint('🔄 Repeat enabled: ${reminder.repeat}');
    debugPrint('📱 Platform: ${defaultTargetPlatform.name}');
    
    if (scheduleTime.isBefore(now)) {
      debugPrint('❌ Cannot schedule notification in the past');
      debugPrint('❌ Schedule: $scheduleTime vs Now: $now');
      return;
    }

    // Test immediate notification for iOS debugging
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint('🧪 Testing immediate notification on iOS...');
      await _showImmediateTestNotification(reminder.title);
    }

    // Unified notification configuration for all platforms
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Channel for reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Reminder',
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );
    
    const macosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macosDetails,
    );
    
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduleTime, tz.local);
    
    // Debug timezone information
    debugPrint('🌍 Local timezone: ${tz.local.name}');
    debugPrint('🕐 Local time now: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('📅 Scheduled TZ time: $scheduledTZ');
    debugPrint('🔄 TZ offset: ${scheduledTZ.timeZoneOffset}');
    
    // Unified scheduling for all platforms
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS-specific scheduling with different approach
        await _notifications.zonedSchedule(
          reminder.id!,
          'Reminder',
          reminder.title,
          scheduledTZ,
          details,
          androidScheduleMode: AndroidScheduleMode.exact, // Required even for iOS
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: reminder.id.toString(),
        );
      } else {
        // Android and other platforms
        await _notifications.zonedSchedule(
          reminder.id!,
          'Reminder',
          reminder.title,
          scheduledTZ,
          details,
          androidScheduleMode: AndroidScheduleMode.exact,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
          payload: reminder.id.toString(),
        );
      }
      
      debugPrint('✅ Notification scheduled successfully for ${reminder.title}');
      debugPrint('🆔 Notification ID: ${reminder.id}');
      debugPrint('📅 Scheduled for: $scheduledTZ');
      
      // Debug repeat information
      debugPrint('🔄 Checking repeat settings...');
      debugPrint('🔄 reminder.repeat: ${reminder.repeat}');
      debugPrint('🔄 reminder.repeatType: ${reminder.repeatType}');
      debugPrint('🔄 reminder.repeatNo: ${reminder.repeatNo}');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
      return;
    }

    // Schedule repeating notifications if needed
    if (reminder.repeat) {
      debugPrint('🔁 Starting repeat notification scheduling...');
      try {
        await _scheduleRepeatingNotifications(reminder, scheduleTime);
        debugPrint('🔁 Repeat scheduling completed successfully!');
      } catch (e) {
        debugPrint('❌ Error in repeat scheduling: $e');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
      }
    } else {
      debugPrint('⏹️ No repeat scheduling - reminder.repeat is false');
    }
  }

  Future<void> _scheduleRepeatingNotifications(Reminder reminder, DateTime baseTime) async {
    try {
      debugPrint('🔁 [DEBUG] Entered _scheduleRepeatingNotifications function');
      debugPrint('🔁 [DEBUG] reminder.repeatType: ${reminder.repeatType}');
      debugPrint('🔁 [DEBUG] reminder.repeatNo: ${reminder.repeatNo}');
      debugPrint('🔁 [DEBUG] baseTime: $baseTime');
      
      const int maxNotifications = 100; // Limit to prevent too many notifications
      
      debugPrint('🔁 Starting repeat scheduling with:');
      debugPrint('🔁 Base time: $baseTime');
      debugPrint('🔁 Repeat type: ${reminder.repeatType}');
      debugPrint('🔁 Repeat interval: ${reminder.repeatNo}');
      
      for (int i = 1; i <= maxNotifications; i++) {
        debugPrint('🔁 [DEBUG] Processing repeat iteration #$i');
        DateTime nextTime;
        
        switch (reminder.repeatType) {
          case 'Daily':
          case 'day':
            nextTime = baseTime.add(Duration(days: i));
            break;
          case 'Weekly':
          case 'week':
            nextTime = baseTime.add(Duration(days: 7 * i));
            break;
          case 'Monthly':
          case 'month':
            nextTime = DateTime(
              baseTime.year,
              baseTime.month + i,
              baseTime.day,
              baseTime.hour,
              baseTime.minute,
            );
            break;
          case 'Yearly':
          case 'year':
            nextTime = DateTime(
              baseTime.year + i,
              baseTime.month,
              baseTime.day,
              baseTime.hour,
              baseTime.minute,
            );
            break;
          case 'hour':
            nextTime = baseTime.add(Duration(hours: i * reminder.repeatNo));
            break;
          case 'minute':
            nextTime = baseTime.add(Duration(minutes: i * reminder.repeatNo));
            break;
          default:
            debugPrint('Unknown repeat type: ${reminder.repeatType}');
            return;
        }
        
        debugPrint('🔁 Scheduling repeat #$i for: $nextTime');
        
        // Stop scheduling if we go too far into the future (5 years)
        if (nextTime.isAfter(DateTime.now().add(const Duration(days: 1825)))) {
          debugPrint('🔁 Stopped scheduling - too far in future');
          break;
        }
        
        const androidDetails = AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          channelDescription: 'Channel for reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Reminder',
          showWhen: true,
        );
        
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        const macosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
          macOS: macosDetails,
        );
        
        final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(nextTime, tz.local);
        
        // Use a different ID for each repeat notification
        final int notificationId = reminder.id! + (i * 10000);
        
        try {
          await _notifications.zonedSchedule(
            notificationId,
            'Reminder',
            reminder.title,
            scheduledTZ,
            details,
            androidScheduleMode: AndroidScheduleMode.exact,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dateAndTime,
            payload: reminder.id.toString(),
          );
          
          debugPrint('✅ Repeat #$i scheduled successfully! ID: $notificationId, Time: $scheduledTZ');
        } catch (e) {
          debugPrint('❌ Error scheduling repeat #$i: $e');
        }
        
        // For testing, only schedule first few for minute repeats
        if (reminder.repeatType == 'minute' && i >= 10) {
          debugPrint('🔁 Limited to 10 minute repeats for testing');
          break;
        }
      }
      
      debugPrint('🔁 Repeat scheduling completed!');
    } catch (e) {
      debugPrint('❌ Error in _scheduleRepeatingNotifications: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  DateTime _parseDateTime(String date, String time) {
    // Parse date in dd/MM/yyyy format
    final dateParts = date.split('/');
    final timeParts = time.split(':');
    
    if (dateParts.length != 3 || timeParts.length != 2) {
      throw FormatException('Invalid date or time format: $date $time');
    }
    
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    
    // Debug time parsing
    debugPrint('🕒 Parsing time: $time');
    debugPrint('📊 Hour: $hour, Minute: $minute');
    
    final parsedDateTime = DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[0]), // day
      hour, // hour (24-hour format)
      minute, // minute
    );
    
    debugPrint('🎯 Parsed DateTime: $parsedDateTime');
    return parsedDateTime;
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
    
    // Cancel all related repeat notifications
    for (int i = 1; i <= 100; i++) {
      await _notifications.cancel(id + (i * 10000));
    }
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<bool> hasPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final bool? granted = await androidImplementation?.areNotificationsEnabled();
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final macosImplementation = _notifications.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final bool? granted = await macosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true; // For web and other platforms
  }

  Future<void> _showImmediateTestNotification(String title) async {
    debugPrint('🧪 Showing immediate test notification...');
    
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Test',
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    try {
      await _notifications.show(
        99999, // Test notification ID
        'Test Notification',
        'This is a test: $title',
        details,
      );
      debugPrint('✅ Test notification shown successfully!');
    } catch (e) {
      debugPrint('❌ Error showing test notification: $e');
    }
  }
}
