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

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Licenses'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App license
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remindly',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Copyright 2015 Blanyal D\'Souza\n\n'
                    'Licensed under the Apache License, Version 2.0 (the "License"); '
                    'you may not use this file except in compliance with the License. '
                    'You may obtain a copy of the License at\n\n'
                    'http://www.apache.org/licenses/LICENSE-2.0\n\n'
                    'Unless required by applicable law or agreed to in writing, software '
                    'distributed under the License is distributed on an "AS IS" BASIS, '
                    'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. '
                    'See the License for the specific language governing permissions and '
                    'limitations under the License.',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Flutter Licenses button
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Flutter Licenses'),
              subtitle: const Text('View all Flutter framework and package licenses'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: 'Remindly',
                  applicationVersion: '1.0.1',
                  applicationLegalese: '© 2015 Blanyal D\'Souza',
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Key dependencies
          Text(
            'Key Dependencies',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('flutter_local_notifications'),
                  subtitle: const Text('Local push notifications'),
                  trailing: const Text('BSD-3-Clause'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('sqflite'),
                  subtitle: const Text('SQLite database'),
                  trailing: const Text('MIT'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('intl'),
                  subtitle: const Text('Internationalization utilities'),
                  trailing: const Text('BSD-3-Clause'),
                ),
                const Divider(),
                ListTile(
                  title: const Text('timezone'),
                  subtitle: const Text('Time zone data and utilities'),
                  trailing: const Text('BSD-2-Clause'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}