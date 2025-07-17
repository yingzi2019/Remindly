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

import 'package:flutter/material.dart';
import '../models/reminder.dart';

class ReminderItem extends StatelessWidget {
  final Reminder reminder;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ReminderItem({
    super.key,
    required this.reminder,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getCircleColor(String title) {
    // Generate a color based on the first letter of the title
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];
    
    if (title.isEmpty) return colors[0];
    
    final index = title.toUpperCase().codeUnitAt(0) % colors.length;
    return colors[index];
  }

  String _getFirstLetter(String title) {
    if (title.isEmpty) return 'A';
    return title.substring(0, 1).toUpperCase();
  }

  String _getRepeatText() {
    if (!reminder.repeat) {
      return 'Repeat Off';
    }
    
    String unit = reminder.repeatType;
    if (reminder.repeatNo > 1) {
      unit = '${reminder.repeatType}s';
    }
    
    return 'Every ${reminder.repeatNo} $unit';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          decoration: isSelected
              ? BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox or circle avatar
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap,
                )
              else
                CircleAvatar(
                  backgroundColor: _getCircleColor(reminder.title),
                  child: Text(
                    _getFirstLetter(reminder.title),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(width: 16),
              
              // Reminder details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Date and time
                    Text(
                      '${reminder.date} ${reminder.time}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Repeat info
                    Text(
                      _getRepeatText(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Active/inactive icon
              Icon(
                reminder.active 
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: reminder.active 
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}