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

import 'package:flutter_test/flutter_test.dart';
import 'package:remindly/models/reminder.dart';
import 'package:remindly/services/storage_service.dart';

void main() {
  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService.instance;
    });

    test('should add and retrieve reminder', () async {
      // Create test reminder
      final reminder = Reminder(
        title: 'Test Reminder',
        date: '2025-07-17',
        time: '14:30',
        repeat: 'None',
        repeatNo: 0,
        repeatType: '',
        active: 1,
      );

      // Add reminder
      final id = await storageService.addReminder(reminder);
      expect(id, greaterThan(0));

      // Retrieve reminder
      final retrievedReminder = await storageService.getReminder(id);
      expect(retrievedReminder, isNotNull);
      expect(retrievedReminder?.title, equals('Test Reminder'));
      expect(retrievedReminder?.date, equals('2025-07-17'));
      expect(retrievedReminder?.time, equals('14:30'));

      // Clean up
      await storageService.deleteReminder(id);
    });

    test('should get all reminders', () async {
      // Add multiple reminders
      final reminder1 = Reminder(
        title: 'Reminder 1',
        date: '2025-07-17',
        time: '10:00',
        repeat: 'None',
        repeatNo: 0,
        repeatType: '',
        active: 1,
      );

      final reminder2 = Reminder(
        title: 'Reminder 2',
        date: '2025-07-18',
        time: '15:00',
        repeat: 'Daily',
        repeatNo: 1,
        repeatType: 'day',
        active: 1,
      );

      final id1 = await storageService.addReminder(reminder1);
      final id2 = await storageService.addReminder(reminder2);

      // Get all reminders
      final allReminders = await storageService.getAllReminders();
      expect(allReminders.length, greaterThanOrEqualTo(2));

      // Verify reminders exist
      final titles = allReminders.map((r) => r.title).toList();
      expect(titles, contains('Reminder 1'));
      expect(titles, contains('Reminder 2'));

      // Clean up
      await storageService.deleteReminder(id1);
      await storageService.deleteReminder(id2);
    });

    test('should update reminder', () async {
      // Add reminder
      final reminder = Reminder(
        title: 'Original Title',
        date: '2025-07-17',
        time: '10:00',
        repeat: 'None',
        repeatNo: 0,
        repeatType: '',
        active: 1,
      );

      final id = await storageService.addReminder(reminder);

      // Update reminder
      final updatedReminder = Reminder(
        id: id,
        title: 'Updated Title',
        date: '2025-07-18',
        time: '15:00',
        repeat: 'Daily',
        repeatNo: 1,
        repeatType: 'day',
        active: 0,
      );

      final updateResult = await storageService.updateReminder(updatedReminder);
      expect(updateResult, equals(1));

      // Verify update
      final retrievedReminder = await storageService.getReminder(id);
      expect(retrievedReminder?.title, equals('Updated Title'));
      expect(retrievedReminder?.date, equals('2025-07-18'));
      expect(retrievedReminder?.time, equals('15:00'));
      expect(retrievedReminder?.repeat, equals('Daily'));
      expect(retrievedReminder?.active, equals(0));

      // Clean up
      await storageService.deleteReminder(id);
    });

    test('should delete reminder', () async {
      // Add reminder
      final reminder = Reminder(
        title: 'To Delete',
        date: '2025-07-17',
        time: '10:00',
        repeat: 'None',
        repeatNo: 0,
        repeatType: '',
        active: 1,
      );

      final id = await storageService.addReminder(reminder);

      // Delete reminder
      final deleteResult = await storageService.deleteReminder(id);
      expect(deleteResult, equals(1));

      // Verify deletion
      final retrievedReminder = await storageService.getReminder(id);
      expect(retrievedReminder, isNull);
    });

    test('should get reminders count', () async {
      final initialCount = await storageService.getRemindersCount();

      // Add reminders
      final reminder1 = Reminder(
        title: 'Count Test 1',
        date: '2025-07-17',
        time: '10:00',
        repeat: 'None',
        repeatNo: 0,
        repeatType: '',
        active: 1,
      );

      final reminder2 = Reminder(
        title: 'Count Test 2',
        date: '2025-07-18',
        time: '15:00',
        repeat: 'None',
        repeatNo: 0,
        repeatType: '',
        active: 1,
      );

      final id1 = await storageService.addReminder(reminder1);
      final id2 = await storageService.addReminder(reminder2);

      // Check count
      final newCount = await storageService.getRemindersCount();
      expect(newCount, equals(initialCount + 2));

      // Clean up
      await storageService.deleteReminder(id1);
      await storageService.deleteReminder(id2);

      // Verify count after cleanup
      final finalCount = await storageService.getRemindersCount();
      expect(finalCount, equals(initialCount));
    });
  });
}
