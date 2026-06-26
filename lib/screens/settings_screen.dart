import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'enroll_screen.dart';
import 'home_screen.dart';

/// API түлхүүр, өнгө аяс тохируулах дэлгэц.
class SettingsScreen extends StatefulWidget {
  final bool firstRun;
  const SettingsScreen({super.key, this.firstRun = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService();
  final _openAi = TextEditingController();
  final _eleven = TextEditingController();
  final _persona = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _openAi.text = await _settings.openAiKey ?? '';
    _eleven.text = await _settings.elevenKey ?? '';
    _persona.text = await _settings.persona;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_openAi.text.trim().isEmpty || _eleven.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Хоёр API түлхүүрийг бөглөнө үү.')),
      );
      return;
    }
    await _settings.setOpenAiKey(_openAi.text);
    await _settings.setElevenKey(_eleven.text);
    await _settings.setPersona(_persona.text);

    if (!mounted) return;
    final voiceId = await _settings.voiceId;
    final next = (voiceId == null || voiceId.isEmpty)
        ? const EnrollScreen()
        : const HomeScreen();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тохиргоо')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.firstRun)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Эхлэхийн тулд API түлхүүрээ оруулна уу. '
                      'Эдгээр нь зөвхөн таны утсан дээр хадгалагдана.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                TextField(
                  controller: _openAi,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'OpenAI API түлхүүр',
                    helperText: 'Яриа таних + хариулт (sk-...)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _eleven,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'ElevenLabs API түлхүүр',
                    helperText: 'Хоолой хуулбарлах + дуу гаргах',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _persona,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Өнгө аяс / зан төлөв',
                    helperText: 'Хариулт ямар маягаар гарахыг тайлбарла',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Хадгалах'),
                ),
              ],
            ),
    );
  }
}
