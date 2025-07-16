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

import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
  }

  static DateTime parseDateTime(String date, String time) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return format.parse('$date $time');
  }

  static bool isInPast(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      final pastDifference = now.difference(dateTime);
      if (pastDifference.inDays > 0) {
        return '${pastDifference.inDays} day${pastDifference.inDays > 1 ? 's' : ''} ago';
      } else if (pastDifference.inHours > 0) {
        return '${pastDifference.inHours} hour${pastDifference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${pastDifference.inMinutes} minute${pastDifference.inMinutes > 1 ? 's' : ''} ago';
      }
    } else {
      if (difference.inDays > 0) {
        return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
      } else {
        return 'in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
      }
    }
  }
}