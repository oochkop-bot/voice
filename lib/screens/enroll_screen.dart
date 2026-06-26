import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/voice_service.dart';
import 'home_screen.dart';

/// 15-30 секунд хоолой бичиж, хуулбарлах (онбординг) дэлгэц.
class EnrollScreen extends StatefulWidget {
  const EnrollScreen({super.key});
  @override
  State<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends State<EnrollScreen> {
  final _audio = AudioService();
  final _settings = SettingsService();
  final _name = TextEditingController(text: 'Миний хоолой');

  bool _recording = false;
  bool _busy = false;
  String? _recordedPath;
  int _seconds = 0;
  Timer? _timer;
  String _status = '';

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      _timer?.cancel();
      final path = await _audio.stopRecording();
      setState(() {
        _recording = false;
        _recordedPath = path;
        _status = _seconds < 15
            ? 'Хэт богино байна. Дор хаяж 15 секунд яриарай.'
            : 'Бичлэг бэлэн. Одоо хуулбарлаж болно.';
      });
      return;
    }

    final ok = await _audio.ensureMicPermission();
    if (!ok) {
      setState(() => _status = 'Микрофоны зөвшөөрөл хэрэгтэй.');
      return;
    }
    await _audio.startRecording(fileName: 'enroll.m4a');
    setState(() {
      _recording = true;
      _seconds = 0;
      _recordedPath = null;
      _status = 'Бичиж байна... 15-30 секунд чөлөөтэй яриарай.';
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _seconds++);
      if (_seconds >= 30) _toggleRecord();
    });
  }

  Future<void> _clone() async {
    if (_recordedPath == null) return;
    setState(() {
      _busy = true;
      _status = 'Хоолойг хуулбарлаж байна...';
    });
    try {
      final key = await _settings.elevenKey ?? '';
      final voice = VoiceService(key);
      final id = await voice.cloneVoice(
        name: _name.text.trim().isEmpty ? 'Миний хоолой' : _name.text.trim(),
        filePath: _recordedPath!,
      );
      await _settings.setVoiceId(id);
      await _settings.setVoiceName(_name.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() => _status = 'Алдаа: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canClone = _recordedPath != null && _seconds >= 15 && !_busy;
    return Scaffold(
      appBar: AppBar(title: const Text('Хоолой бүртгэх')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Хуулбарлах хүний хоолойг 15-30 секунд бичнэ үү. '
              'Чимээгүй орчинд, тодорхой яриарай.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Хоолойн нэр',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '${_seconds.toString().padLeft(2, '0')} сек',
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _toggleRecord,
              icon: Icon(_recording ? Icons.stop : Icons.mic),
              label: Text(_recording ? 'Зогсоох' : 'Бичиж эхлэх'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: canClone ? _clone : null,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text('Хоолойг хуулбарлах'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
            const SizedBox(height: 24),
            Text(_status, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
