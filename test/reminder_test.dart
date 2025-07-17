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

void main() {
  group('Reminder Model Tests', () {
    test('should create a reminder with default values', () {
      final reminder = Reminder(
        title: 'Test Reminder',
        date: '01/01/2024',
        time: '12:00',
      );

      expect(reminder.title, 'Test Reminder');
      expect(reminder.date, '01/01/2024');
      expect(reminder.time, '12:00');
      expect(reminder.repeat, false);
      expect(reminder.repeatNo, 1);
      expect(reminder.repeatType, 'hour');
      expect(reminder.active, true);
    });

    test('should convert to and from map correctly', () {
      final reminder = Reminder(
        id: 1,
        title: 'Test Reminder',
        date: '01/01/2024',
        time: '12:00',
        repeat: true,
        repeatNo: 2,
        repeatType: 'day',
        active: false,
      );

      final map = reminder.toMap();
      final reminderFromMap = Reminder.fromMap(map);

      expect(reminderFromMap.id, reminder.id);
      expect(reminderFromMap.title, reminder.title);
      expect(reminderFromMap.date, reminder.date);
      expect(reminderFromMap.time, reminder.time);
      expect(reminderFromMap.repeat, reminder.repeat);
      expect(reminderFromMap.repeatNo, reminder.repeatNo);
      expect(reminderFromMap.repeatType, reminder.repeatType);
      expect(reminderFromMap.active, reminder.active);
    });

    test('should create copy with updated values', () {
      final original = Reminder(
        title: 'Original Title',
        date: '01/01/2024',
        time: '12:00',
      );

      final updated = original.copyWith(title: 'Updated Title');

      expect(updated.title, 'Updated Title');
      expect(updated.date, original.date);
      expect(updated.time, original.time);
    });
  });
}