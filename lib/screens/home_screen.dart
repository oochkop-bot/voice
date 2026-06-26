import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/stt_service.dart';
import '../services/chat_service.dart';
import '../services/voice_service.dart';
import 'settings_screen.dart';
import 'enroll_screen.dart';

class _Msg {
  final String text;
  final bool fromUser;
  _Msg(this.text, this.fromUser);
}

/// Үндсэн яриа дэлгэц: асууж → дуугаар хариулдаг.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _audio = AudioService();
  final _settings = SettingsService();

  final List<_Msg> _messages = [];
  final List<Map<String, String>> _history = [];

  bool _recording = false;
  bool _processing = false;
  String _status = 'Асуухын тулд микрофон дээр дарна уу';

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _onMicTap() async {
    if (_processing) return;

    if (_recording) {
      final path = await _audio.stopRecording();
      setState(() => _recording = false);
      if (path != null) await _process(path);
      return;
    }

    final ok = await _audio.ensureMicPermission();
    if (!ok) {
      setState(() => _status = 'Микрофоны зөвшөөрөл хэрэгтэй.');
      return;
    }
    await _audio.startRecording(fileName: 'question.m4a');
    setState(() {
      _recording = true;
      _status = 'Сонсож байна... Асуултаа хэлээд дахин дарна уу.';
    });
  }

  Future<void> _process(String audioPath) async {
    setState(() {
      _processing = true;
      _status = 'Бодож байна...';
    });
    try {
      final openAiKey = await _settings.openAiKey ?? '';
      final elevenKey = await _settings.elevenKey ?? '';
      final voiceId = await _settings.voiceId ?? '';
      final persona = await _settings.persona;

      // 1) Яриа -> текст
      final stt = SttService(openAiKey);
      final question = await stt.transcribe(audioPath);
      if (question.isEmpty) {
        setState(() => _status = 'Дуу сонсогдсонгүй. Дахин оролдоно уу.');
        return;
      }
      setState(() => _messages.add(_Msg(question, true)));

      // 2) Хариулт боловсруулах
      final chat = ChatService(openAiKey);
      final reply = await chat.answer(
        question: question,
        persona: persona,
        history: _history,
      );
      setState(() => _messages.add(_Msg(reply, false)));

      _history.add({'role': 'user', 'content': question});
      _history.add({'role': 'assistant', 'content': reply});
      if (_history.length > 12) {
        _history.removeRange(0, _history.length - 12);
      }

      // 3) Хуулбарласан хоолойгоор дуу гаргах
      setState(() => _status = 'Хариулж байна...');
      final voice = VoiceService(elevenKey);
      final bytes = await voice.synthesize(voiceId: voiceId, text: reply);
      await _audio.playBytesAsFile(bytes);

      setState(() => _status = 'Дараагийн асуултад бэлэн');
    } catch (e) {
      setState(() => _status = 'Алдаа: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _openMenu(String value) {
    if (value == 'settings') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()));
    } else if (value == 'reenroll') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const EnrollScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Хоолой Клон'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _openMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reenroll', child: Text('Хоолой дахин бүртгэх')),
              PopupMenuItem(value: 'settings', child: Text('Тохиргоо')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Асуултаа ярьж асуу — хуулбарласан хоолойгоор '
                        'хариулна.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.fromUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: m.fromUser
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(m.text),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_status,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 8),
            child: GestureDetector(
              onTap: _onMicTap,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _recording
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                ),
                child: _processing
                    ? const Padding(
                        padding: EdgeInsets.all(26),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3),
                      )
                    : Icon(
                        _recording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 38,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
