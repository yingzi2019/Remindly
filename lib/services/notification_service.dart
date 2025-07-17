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

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_initialized) await initialize();

    final DateTime scheduleTime = _parseDateTime(reminder.date, reminder.time);
    
    if (scheduleTime.isBefore(DateTime.now())) {
      debugPrint('Cannot schedule notification in the past');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const iosDetails = DarwinNotificationDetails();
    const macosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macosDetails,
    );

    // Schedule the initial notification
    await _notifications.zonedSchedule(
      reminder.id!,
      'Reminder',
      reminder.title,
      tz.TZDateTime.from(scheduleTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: reminder.id.toString(),
    );

    // Schedule repeating notifications if needed
    if (reminder.repeat) {
      await _scheduleRepeatingNotifications(reminder, scheduleTime);
    }
  }

  Future<void> _scheduleRepeatingNotifications(Reminder reminder, DateTime initialTime) async {
    // Schedule up to 50 future notifications for repeating reminders
    DateTime currentTime = initialTime;
    
    for (int i = 1; i <= 50; i++) {
      currentTime = _calculateNextRepeatTime(currentTime, reminder.repeatNo, reminder.repeatType);
      
      if (currentTime.year > DateTime.now().year + 5) {
        break; // Don't schedule too far in the future
      }

      await _notifications.zonedSchedule(
        reminder.id! + i * 1000, // Use different ID for each repeat
        'Reminder',
        reminder.title,
        tz.TZDateTime.from(currentTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Reminder notifications',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: false,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: reminder.id.toString(),
      );
    }
  }

  DateTime _calculateNextRepeatTime(DateTime current, int repeatNo, String repeatType) {
    switch (repeatType.toLowerCase()) {
      case 'minute':
        return current.add(Duration(minutes: repeatNo));
      case 'hour':
        return current.add(Duration(hours: repeatNo));
      case 'day':
        return current.add(Duration(days: repeatNo));
      case 'week':
        return current.add(Duration(days: repeatNo * 7));
      case 'month':
        return DateTime(
          current.year,
          current.month + repeatNo,
          current.day,
          current.hour,
          current.minute,
        );
      case 'year':
        return DateTime(
          current.year + repeatNo,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
      default:
        return current.add(Duration(hours: repeatNo));
    }
  }

  DateTime _parseDateTime(String date, String time) {
    // Parse date in format "dd/MM/yyyy"
    final dateParts = date.split('/');
    final day = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final year = int.parse(dateParts[2]);

    // Parse time in format "HH:mm"
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return DateTime(year, month, day, hour, minute);
  }

  Future<void> cancelReminder(int reminderId) async {
    await _notifications.cancel(reminderId);
    
    // Cancel all repeating notifications for this reminder
    for (int i = 1; i <= 50; i++) {
      await _notifications.cancel(reminderId + i * 1000);
    }
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}