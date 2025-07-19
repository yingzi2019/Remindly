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
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final StorageService _storageService = StorageService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _repeat = false;
  int _repeatNo = 1;
  String _repeatType = 'hour';
  bool _active = true;
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

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final reminder = Reminder(
        title: _titleController.text.trim(),
        date: DateFormat('dd/MM/yyyy').format(_selectedDateTime),
        time: DateFormat('HH:mm').format(_selectedDateTime),
        repeat: _repeat,
        repeatNo: _repeatNo,
        repeatType: _repeatType,
        active: _active,
      );

      final id = await _storageService.addReminder(reminder);
      
      if (_active) {
        final reminderWithId = reminder.copyWith(id: id);
        await _notificationService.scheduleReminder(reminderWithId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder saved successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reminder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reminder'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveReminder,
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