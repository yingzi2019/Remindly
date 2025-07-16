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
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class EditReminderScreen extends StatefulWidget {
  final Reminder reminder;

  const EditReminderScreen({super.key, required this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  final DatabaseService _databaseService = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  late DateTime _selectedDateTime;
  late bool _repeat;
  late int _repeatNo;
  late String _repeatType;
  late bool _active;
  bool _isLoading = false;

  final List<String> _repeatTypes = [
    'minute',
    'hour', 
    'day',
    'week',
    'month',
    'year',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder.title);
    
    // Parse the existing date and time
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final date = dateFormat.parse(widget.reminder.date);
    final time = timeFormat.parse(widget.reminder.time);
    
    _selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    
    _repeat = widget.reminder.repeat;
    _repeatNo = widget.reminder.repeatNo;
    _repeatType = widget.reminder.repeatType;
    _active = widget.reminder.active;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _updateReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedReminder = widget.reminder.copyWith(
        title: _titleController.text.trim(),
        date: DateFormat('dd/MM/yyyy').format(_selectedDateTime),
        time: DateFormat('HH:mm').format(_selectedDateTime),
        repeat: _repeat,
        repeatNo: _repeatNo,
        repeatType: _repeatType,
        active: _active,
      );

      await _databaseService.updateReminder(updatedReminder);
      
      // Cancel existing notifications
      await _notificationService.cancelReminder(widget.reminder.id!);
      
      // Schedule new notifications if active
      if (_active) {
        await _notificationService.scheduleReminder(updatedReminder);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating reminder: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _notificationService.cancelReminder(widget.reminder.id!);
      await _databaseService.deleteReminder(widget.reminder.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting reminder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Reminder'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _deleteReminder,
            icon: const Icon(Icons.delete),
          ),
          TextButton(
            onPressed: _isLoading ? null : _updateReminder,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Reminder Title',
                hintText: 'Enter reminder title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 24),

            // Date and time selection
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Date & Time'),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(_selectedDateTime),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectDateTime,
              ),
            ),

            const SizedBox(height: 16),

            // Active toggle
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: const Text('Active'),
                subtitle: Text(_active ? 'Notification enabled' : 'Notification disabled'),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
            ),

            const SizedBox(height: 16),

            // Repeat toggle
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.repeat),
                title: const Text('Repeat'),
                subtitle: Text(_repeat ? 'Repeating reminder' : 'One-time reminder'),
                value: _repeat,
                onChanged: (value) => setState(() => _repeat = value),
              ),
            ),

            // Repeat options (only shown when repeat is enabled)
            if (_repeat) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeat Options',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      // Repeat interval
                      Row(
                        children: [
                          const Text('Every'),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: _repeatNo.toString(),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final number = int.tryParse(value);
                                if (number != null && number > 0) {
                                  setState(() => _repeatNo = number);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _repeatType,
                            items: _repeatTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _repeatType = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}