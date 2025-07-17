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

    // Initialize timezone
    tz.initializeTimeZones();

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
    
    await _notifications.initialize(initSettings);
    
    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        
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
    
    if (scheduleTime.isBefore(DateTime.now())) {
      debugPrint('Cannot schedule notification in the past');
      return;
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
    
    final tz.TZDateTime scheduledTZ = tz.TZDateTime.from(scheduleTime, tz.local);
    
    // Schedule the initial notification
    await _notifications.zonedSchedule(
      reminder.id!,
      'Reminder',
      reminder.title,
      scheduledTZ,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: reminder.id.toString(),
    );

    // Schedule repeating notifications if needed
    if (reminder.repeat) {
      await _scheduleRepeatingNotifications(reminder, scheduleTime);
    }
  }

  Future<void> _scheduleRepeatingNotifications(Reminder reminder, DateTime baseTime) async {
    const int maxNotifications = 100; // Limit to prevent too many notifications
    
    for (int i = 1; i <= maxNotifications; i++) {
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
          return;
      }
      
      // Stop scheduling if we go too far into the future (5 years)
      if (nextTime.isAfter(DateTime.now().add(const Duration(days: 1825)))) {
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
      final int notificationId = reminder.id! + i * 10000;
      
      await _notifications.zonedSchedule(
        notificationId,
        'Reminder',
        reminder.title,
        scheduledTZ,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
        payload: reminder.id.toString(),
      );
    }
  }

  DateTime _parseDateTime(String date, String time) {
    // Parse date in dd/MM/yyyy format
    final dateParts = date.split('/');
    final timeParts = time.split(':');
    
    if (dateParts.length != 3 || timeParts.length != 2) {
      throw FormatException('Invalid date or time format: $date $time');
    }
    
    return DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[1]), // month
      int.parse(dateParts[0]), // day
      int.parse(timeParts[0]), // hour
      int.parse(timeParts[1]), // minute
    );
  }

  Future<void> cancelReminder(int id) async {
    await _notifications.cancel(id);
    
    // Cancel all related repeat notifications
    for (int i = 1; i <= 100; i++) {
      await _notifications.cancel(id + i * 10000);
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
}