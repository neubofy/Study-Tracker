import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Blocker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<BlockedApp> blockedApps = [];
  final List<CalendarEvent> calendarEvents = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Blocker'),
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(icon: Icon(Icons.block), text: 'Blocked Apps'),
                Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Blocked Apps Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add App to Block'),
                          onPressed: _addBlockedApp,
                        ),
                      ),
                      Expanded(
                        child: blockedApps.isEmpty
                            ? const Center(
                                child: Text('No apps blocked yet'),
                              )
                            : ListView.builder(
                                itemCount: blockedApps.length,
                                itemBuilder: (context, index) {
                                  final app = blockedApps[index];
                                  return ListTile(
                                    leading: const Icon(Icons.apps),
                                    title: Text(app.name),
                                    subtitle: Text(
                                      'Block from ${app.startTime} to ${app.endTime}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          blockedApps.removeAt(index);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  // Calendar Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Connect Google Calendar'),
                          onPressed: _connectCalendar,
                        ),
                      ),
                      Expanded(
                        child: calendarEvents.isEmpty
                            ? const Center(
                                child: Text('No calendar events synced'),
                              )
                            : ListView.builder(
                                itemCount: calendarEvents.length,
                                itemBuilder: (context, index) {
                                  final event = calendarEvents[index];
                                  return ListTile(
                                    leading: const Icon(Icons.event),
                                    title: Text(event.title),
                                    subtitle: Text(
                                      '${event.startTime} - ${event.endTime}',
                                    ),
                                    trailing: Checkbox(
                                      value: event.blockApps,
                                      onChanged: (value) {
                                        setState(() {
                                          event.blockApps = value ?? false;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addBlockedApp() {
    showDialog(
      context: context,
      builder: (context) => _AddAppDialog(
        onAdd: (app) {
          setState(() {
            blockedApps.add(app);
          });
        },
      ),
    );
  }

  void _connectCalendar() {
    // TODO: Implement Google Calendar OAuth
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Calendar integration coming soon'),
      ),
    );
  }
}

class _AddAppDialog extends StatefulWidget {
  final Function(BlockedApp) onAdd;

  const _AddAppDialog({required this.onAdd});

  @override
  State<_AddAppDialog> createState() => _AddAppDialogState();
}

class _AddAppDialogState extends State<_AddAppDialog> {
  late TextEditingController nameController;
  late TextEditingController startTimeController;
  late TextEditingController endTimeController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    startTimeController = TextEditingController(text: '09:00');
    endTimeController = TextEditingController(text: '17:00');
  }

  @override
  void dispose() {
    nameController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add App to Block'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'App Name',
              hintText: 'e.g., Instagram',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: startTimeController,
            decoration: const InputDecoration(
              labelText: 'Start Time',
              hintText: 'HH:MM',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: endTimeController,
            decoration: const InputDecoration(
              labelText: 'End Time',
              hintText: 'HH:MM',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.isNotEmpty) {
              widget.onAdd(
                BlockedApp(
                  name: nameController.text,
                  startTime: startTimeController.text,
                  endTime: endTimeController.text,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class BlockedApp {
  final String name;
  final String startTime;
  final String endTime;

  BlockedApp({
    required this.name,
    required this.startTime,
    required this.endTime,
  });
}

class CalendarEvent {
  final String title;
  final String startTime;
  final String endTime;
  bool blockApps;

  CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.blockApps = false,
  });
}
