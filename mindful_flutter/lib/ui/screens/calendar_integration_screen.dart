import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mindful/services/google_calendar_service.dart';
import 'package:mindful/database/app_database.dart';
import 'package:mindful/database/schema.dart';

class CalendarIntegrationScreen extends StatefulWidget {
  const CalendarIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<CalendarIntegrationScreen> createState() =>
      _CalendarIntegrationScreenState();
}

class _CalendarIntegrationScreenState extends State<CalendarIntegrationScreen> {
  bool _isAutoFocusEnabled = false;
  bool _isConnected = false;
  String _userEmail = '';
  bool _isLoading = false;
  List<GoogleSignInAccount> _availableAccounts = [];
  String? _selectedEmail;

  @override
  void initState() {
    super.initState();
    _loadCalendarStatus();
    _loadAvailableAccounts();
  }

  Future<void> _loadCalendarStatus() async {
    final calendarService = context.read<GoogleCalendarService>();
    final db = context.read<AppDatabase>();

    final integration = await db.getCalendarIntegration();

    setState(() {
      _isConnected = integration?.isConnected ?? false;
      _isAutoFocusEnabled = integration?.isAutoFocusEnabled ?? false;
      _userEmail = integration?.userEmail ?? '';
    });
  }

  Future<void> _loadAvailableAccounts() async {
    final calendarService = context.read<GoogleCalendarService>();
    try {
      final accounts = await calendarService.getAvailableAccounts();
      setState(() {
        _availableAccounts = accounts;
        if (accounts.isNotEmpty && _selectedEmail == null) {
          _selectedEmail = accounts.first.email;
        }
      });
    } catch (e) {
      debugPrint('[CalendarIntegrationScreen] Error loading accounts: $e');
    }
  }

  Future<void> _handleConnect() async {
    if (_selectedEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final db = context.read<AppDatabase>();
    final calendarService = context.read<GoogleCalendarService>();

    setState(() => _isLoading = true);

    try {
      // Save selected email and connect
      await calendarService.connectWithEmail(_selectedEmail!);

      // Fetch calendar events
      await calendarService.fetchCalendarEvents();

      // Start periodic sync
      calendarService.startPeriodicSync(
        interval: const Duration(minutes: 5),
      );

      // Update database
      await db.insertOrUpdateCalendarIntegration(
        CalendarIntegrationsCompanion(
          userEmail: Value(_selectedEmail!),
          isConnected: const Value(true),
        ),
      );

      // Reload status
      await _loadCalendarStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to $_selectedEmail!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Calendar?'),
        content: const Text(
          'Auto-focus sessions from calendar events will be disabled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final calendarService = context.read<GoogleCalendarService>();
      final db = context.read<AppDatabase>();

      setState(() => _isLoading = true);

      try {
        await calendarService.disconnect();
        calendarService.stopPeriodicSync();

        await db.insertOrUpdateCalendarIntegration(
          const CalendarIntegrationsCompanion(
            isConnected: Value(false),
            isAutoFocusEnabled: Value(false),
          ),
        );

        setState(() {
          _isConnected = false;
          _isAutoFocusEnabled = false;
          _userEmail = '';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Calendar disconnected'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAutoFocus(bool value) async {
    final db = context.read<AppDatabase>();
    final calendarService = context.read<GoogleCalendarService>();

    try {
      await db.insertOrUpdateCalendarIntegration(
        CalendarIntegrationsCompanion(
          isAutoFocusEnabled: Value(value),
        ),
      );

      if (value) {
        // Start calendar monitoring
        await calendarService.startPeriodicSync();
      } else {
        calendarService.stopPeriodicSync();
      }

      setState(() => _isAutoFocusEnabled = value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Auto Focus Mode enabled'
                : 'Auto Focus Mode disabled',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Integration'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isConnected ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isConnected ? 'Connected' : 'Not Connected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isConnected ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (_isConnected) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Account: $_userEmail',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (!_isConnected) ...[
                // Account Selection Section
                const Text(
                  'Select Your Calendar Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_availableAccounts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedEmail,
                      isExpanded: true,
                      underline: const SizedBox(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      items: _availableAccounts.map((account) {
                        return DropdownMenuItem(
                          value: account.email,
                          child: Text(account.email),
                        );
                      }).toList(),
                      onChanged: (email) {
                        setState(() => _selectedEmail = email);
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleConnect,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: _isLoading
                        ? const Text('Connecting...')
                        : const Text('Connect Calendar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ] else ...[
                // Disconnect Section
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleDisconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Disconnect Calendar'),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Auto Focus Settings
              const Text(
                'Auto Focus Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: const Text('Auto Focus Mode'),
                  subtitle: const Text(
                    'Automatically enable focus mode when a calendar event is active',
                  ),
                  trailing: Switch(
                    value: _isAutoFocusEnabled && _isConnected,
                    onChanged: _isConnected && !_isLoading
                        ? (value) => _toggleAutoFocus(value)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Section
              if (_isConnected)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How it works:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• App checks your calendar every 5 minutes\n'
                          '• When an event starts, Focus Mode activates\n'
                          '• DND is enabled, apps are blocked\n'
                          '• When the event ends, restrictions lift\n'
                          '• You can manually adjust during focus sessions',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isConnected)
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Connect your Google Calendar to:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Automatically trigger Focus Mode during events\n'
                          '• Get DND + app blocking automatically\n'
                          '• Stay focused without manual setup\n'
                          '• All data stays on your device',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Privacy Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Privacy: Neubofy Productive only reads your calendar events locally. No data is sent to external servers.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
