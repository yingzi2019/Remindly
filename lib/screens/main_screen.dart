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
import '../widgets/reminder_item.dart';
import 'add_reminder_screen.dart';
import 'edit_reminder_screen.dart';
import 'licenses_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  
  List<Reminder> _reminders = [];
  final Set<int> _selectedItems = <int>{};
  bool _isSelectionMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    
    try {
      final reminders = await _databaseService.getAllReminders();
      
      // Sort reminders by date and time
      reminders.sort((a, b) {
        final dateTimeA = _parseDateTime(a.date, a.time);
        final dateTimeB = _parseDateTime(b.date, b.time);
        return dateTimeA.compareTo(dateTimeB);
      });
      
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reminders: $e')),
        );
      }
    }
  }

  DateTime _parseDateTime(String date, String time) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return format.parse('$date $time');
  }

  void _onReminderTap(Reminder reminder) {
    if (_isSelectionMode) {
      _toggleSelection(reminder.id!);
    } else {
      _editReminder(reminder);
    }
  }

  void _onReminderLongPress(Reminder reminder) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedItems.add(reminder.id!);
      });
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedItems.contains(id)) {
        _selectedItems.remove(id);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  Future<void> _deleteSelectedReminders() async {
    try {
      // Cancel notifications for selected reminders
      for (final id in _selectedItems) {
        await _notificationService.cancelReminder(id);
      }
      
      // Delete from database
      await _databaseService.deleteReminders(_selectedItems.toList());
      
      setState(() {
        _reminders.removeWhere((reminder) => _selectedItems.contains(reminder.id));
        _selectedItems.clear();
        _isSelectionMode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminders deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting reminders: $e')),
        );
      }
    }
  }

  void _addReminder() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const AddReminderScreen()),
    );
    
    if (result == true) {
      _loadReminders();
    }
  }

  void _editReminder(Reminder reminder) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditReminderScreen(reminder: reminder),
      ),
    );
    
    if (result == true) {
      _loadReminders();
    }
  }

  void _showLicenses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LicensesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_selectedItems.length} selected'
            : 'Remindly'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedItems.isNotEmpty ? _deleteSelectedReminders : null,
                ),
              ]
            : [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'licenses') {
                      _showLicenses();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'licenses',
                      child: Text('Licenses'),
                    ),
                  ],
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No reminders yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to create your first reminder',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    final isSelected = _selectedItems.contains(reminder.id);
                    
                    return ReminderItem(
                      reminder: reminder,
                      isSelected: isSelected,
                      isSelectionMode: _isSelectionMode,
                      onTap: () => _onReminderTap(reminder),
                      onLongPress: () => _onReminderLongPress(reminder),
                    );
                  },
                ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _addReminder,
              child: const Icon(Icons.add),
            ),
    );
  }
}