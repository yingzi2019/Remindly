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

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';

abstract class StorageService {
  static StorageService? _instance;
  
  static StorageService get instance {
    if (_instance == null) {
      if (kIsWeb) {
        _instance = WebStorageService();
      } else {
        _instance = WebStorageService(); // Use WebStorageService for all platforms for now
      }
    }
    return _instance!;
  }

  Future<int> addReminder(Reminder reminder);
  Future<List<Reminder>> getAllReminders();
  Future<Reminder?> getReminder(int id);
  Future<int> updateReminder(Reminder reminder);
  Future<int> deleteReminder(int id);
  Future<int> deleteReminders(List<int> ids);
  Future<int> getRemindersCount();
}

class WebStorageService extends StorageService {
  static const String _keyPrefix = 'reminder_';
  static const String _countKey = 'reminder_count';
  static const String _allIdsKey = 'reminder_all_ids';

  @override
  Future<int> addReminder(Reminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get next ID
    int nextId = await _getNextId();
    
    // Create reminder with new ID
    final newReminder = Reminder(
      id: nextId,
      title: reminder.title,
      date: reminder.date,
      time: reminder.time,
      repeat: reminder.repeat,
      repeatNo: reminder.repeatNo,
      repeatType: reminder.repeatType,
      active: reminder.active,
    );
    
    // Save reminder
    await prefs.setString('$_keyPrefix$nextId', jsonEncode(newReminder.toMap()));
    
    // Update ID list
    List<String> allIds = prefs.getStringList(_allIdsKey) ?? [];
    allIds.add(nextId.toString());
    await prefs.setStringList(_allIdsKey, allIds);
    
    return nextId;
  }

  @override
  Future<List<Reminder>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> allIds = prefs.getStringList(_allIdsKey) ?? [];
    
    List<Reminder> reminders = [];
    for (String idStr in allIds) {
      String? reminderStr = prefs.getString('$_keyPrefix$idStr');
      if (reminderStr != null) {
        Map<String, dynamic> reminderMap = jsonDecode(reminderStr);
        reminders.add(Reminder.fromMap(reminderMap));
      }
    }
    
    return reminders;
  }

  @override
  Future<Reminder?> getReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    String? reminderStr = prefs.getString('$_keyPrefix$id');
    
    if (reminderStr != null) {
      Map<String, dynamic> reminderMap = jsonDecode(reminderStr);
      return Reminder.fromMap(reminderMap);
    }
    
    return null;
  }

  @override
  Future<int> updateReminder(Reminder reminder) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (reminder.id != null) {
      await prefs.setString('$_keyPrefix${reminder.id}', jsonEncode(reminder.toMap()));
      return 1;
    }
    
    return 0;
  }

  @override
  Future<int> deleteReminder(int id) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove reminder
    bool removed = await prefs.remove('$_keyPrefix$id');
    
    if (removed) {
      // Update ID list
      List<String> allIds = prefs.getStringList(_allIdsKey) ?? [];
      allIds.remove(id.toString());
      await prefs.setStringList(_allIdsKey, allIds);
      return 1;
    }
    
    return 0;
  }

  @override
  Future<int> deleteReminders(List<int> ids) async {
    int deletedCount = 0;
    for (int id in ids) {
      deletedCount += await deleteReminder(id);
    }
    return deletedCount;
  }

  @override
  Future<int> getRemindersCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> allIds = prefs.getStringList(_allIdsKey) ?? [];
    return allIds.length;
  }

  Future<int> _getNextId() async {
    final prefs = await SharedPreferences.getInstance();
    int currentId = prefs.getInt(_countKey) ?? 0;
    int nextId = currentId + 1;
    await prefs.setInt(_countKey, nextId);
    return nextId;
  }
}
