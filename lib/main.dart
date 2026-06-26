import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/enroll_screen.dart';

void main() {
  runApp(const HooloiApp());
}

class HooloiApp extends StatelessWidget {
  const HooloiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Хоолой Клон',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B6CFF),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B6CFF),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const _Gate(),
    );
  }
}

/// Тохиргоо хийгдсэн эсэхээс хамаарч эхлэх дэлгэцийг сонгоно.
class _Gate extends StatefulWidget {
  const _Gate();
  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  final _settings = SettingsService();
  Widget? _start;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final openAi = await _settings.openAiKey;
    final eleven = await _settings.elevenKey;
    final voiceId = await _settings.voiceId;

    Widget next;
    if ((openAi == null || openAi.isEmpty) ||
        (eleven == null || eleven.isEmpty)) {
      next = const SettingsScreen(firstRun: true);
    } else if (voiceId == null || voiceId.isEmpty) {
      next = const EnrollScreen();
    } else {
      next = const HomeScreen();
    }
    if (mounted) setState(() => _start = next);
  }

  @override
  Widget build(BuildContext context) {
    if (_start == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _start!;
  }
}
