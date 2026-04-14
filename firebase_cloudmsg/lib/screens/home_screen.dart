import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fcm_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FCMService _fcmService = FCMService();

  // --- UI state driven entirely by incoming FCM payloads ---
  String _statusText = 'Waiting for a cloud message...';
  String _messageTitle = '—';
  String _messageBody = '—';
  String _rawData = '—';
  Color _backgroundColor = Colors.white;
  String? _fcmToken;

  // Maps data['theme'] values from the payload to background colors.
  // Add more entries here if you use other theme names in your payloads.
  static const Map<String, Color> _themeColors = {
    'green': Color(0xFFE8F5E9),
    'blue': Color(0xFFE3F2FD),
    'red': Color(0xFFFFEBEE),
    'yellow': Color(0xFFFFFDE7),
  };

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    // Fetch the token first so it appears on screen immediately,
    // independently of any incoming message.
    final token = await _fcmService.getToken();
    setState(() => _fcmToken = token);

    // Wire the service to this screen's _handleMessage.
    // FCMService will request permission and register all three listeners.
    await _fcmService.initialize(onData: _handleMessage);
  }

  /// Called by FCMService for every message (foreground, background tap,
  /// and terminated tap). Updates UI state from the payload.
  void _handleMessage(RemoteMessage message) {
    debugPrint('[UI] _handleMessage → title: ${message.notification?.title}');
    debugPrint('[UI] _handleMessage → data: ${message.data}');

    setState(() {
      _statusText = 'Message received!';

      // Notification fields — safe fallback if notification block is absent
      _messageTitle = message.notification?.title ?? '(no title in payload)';
      _messageBody = message.notification?.body ?? '(no body in payload)';

      // Raw data map — useful for debugging exact key names
      _rawData = message.data.isEmpty
          ? '(no data block in payload)'
          : message.data.toString();

      // data['theme'] → background color.
      // Falls back to white if key is missing or unrecognized.
      final themeKey = message.data['theme'] as String?;
      _backgroundColor = _themeColors[themeKey] ?? Colors.white;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // changes when theme key arrives
      appBar: AppBar(title: const Text('FCM Demo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status banner — changes from "Waiting..." to "Message received!"
            _statusBanner(),
            const SizedBox(height: 24),

            // Payload fields
            _labeledField('Title', _messageTitle),
            _labeledField('Body', _messageBody),
            _labeledField('Data', _rawData),
            const SizedBox(height: 32),

            // Token section — tap to copy for use in Firebase Console
            const Text(
              'FCM Token  (tap to copy):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _tokenBox(),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _statusText,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _labeledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _tokenBox() {
    return GestureDetector(
      onTap: () {
        if (_fcmToken == null) return;
        Clipboard.setData(ClipboardData(text: _fcmToken!));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM token copied to clipboard')),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          _fcmToken ?? 'Fetching token...',
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
