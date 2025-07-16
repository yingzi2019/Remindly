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

class Reminder {
  int? id;
  String title;
  String date;
  String time;
  bool repeat;
  int repeatNo;
  String repeatType;
  bool active;

  Reminder({
    this.id,
    required this.title,
    required this.date,
    required this.time,
    this.repeat = false,
    this.repeatNo = 1,
    this.repeatType = 'hour',
    this.active = true,
  });

  // Convert from Map (for database operations)
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      repeat: map['repeat'] == 1,
      repeatNo: map['repeat_no']?.toInt() ?? 1,
      repeatType: map['repeat_type'] ?? 'hour',
      active: map['active'] == 1,
    );
  }

  // Convert to Map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'repeat': repeat ? 1 : 0,
      'repeat_no': repeatNo,
      'repeat_type': repeatType,
      'active': active ? 1 : 0,
    };
  }

  // Create a copy with updated fields
  Reminder copyWith({
    int? id,
    String? title,
    String? date,
    String? time,
    bool? repeat,
    int? repeatNo,
    String? repeatType,
    bool? active,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      repeat: repeat ?? this.repeat,
      repeatNo: repeatNo ?? this.repeatNo,
      repeatType: repeatType ?? this.repeatType,
      active: active ?? this.active,
    );
  }

  @override
  String toString() {
    return 'Reminder{id: $id, title: $title, date: $date, time: $time, repeat: $repeat, repeatNo: $repeatNo, repeatType: $repeatType, active: $active}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reminder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          date == other.date &&
          time == other.time &&
          repeat == other.repeat &&
          repeatNo == other.repeatNo &&
          repeatType == other.repeatType &&
          active == other.active;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      date.hashCode ^
      time.hashCode ^
      repeat.hashCode ^
      repeatNo.hashCode ^
      repeatType.hashCode ^
      active.hashCode;
}