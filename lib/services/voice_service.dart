import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ElevenLabs ашиглан хоолой хуулбарлах (clone) ба нийлэгжүүлэх (TTS).
class VoiceService {
  final String apiKey;
  VoiceService(this.apiKey);

  static const _base = 'https://api.elevenlabs.io/v1';

  /// Монгол кирилл текстийг латин руу хувиргаж, зөвхөн ASCII үлдээнэ.
  static String _ascii(String input, {String fallback = 'MyVoice'}) {
    const map = {
      'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
      'ж': 'j', 'з': 'z', 'и': 'i', 'й': 'i', 'к': 'k', 'л': 'l', 'м': 'm',
      'н': 'n', 'о': 'o', 'ө': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't',
      'у': 'u', 'ү': 'u', 'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch',
      'ш': 'sh', 'щ': 'shch', 'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e',
      'ю': 'yu', 'я': 'ya',
    };
    final buf = StringBuffer();
    for (final ch in input.toLowerCase().split('')) {
      if (map.containsKey(ch)) {
        buf.write(map[ch]);
      } else if (ch.codeUnitAt(0) < 128) {
        buf.write(ch);
      }
    }
    final out = buf.toString().trim();
    return out.isEmpty ? fallback : out;
  }

  Future<String> cloneVoice({
    required String name,
    required String filePath,
    String description = 'Voice cloned via app',
  }) async {
    final uri = Uri.parse('$_base/voices/add');
    final request = http.MultipartRequest('POST', uri)
      ..headers['xi-api-key'] = apiKey
      ..fields['name'] = _ascii(name)
      ..fields['description'] = _ascii(description, fallback: 'cloned voice')
      ..files.add(await http.MultipartFile.fromPath(
        'files',
        filePath,
        filename: 'sample.m4a',
      ));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw HttpException(
          'Хоолой хуулбарлах алдаа (${resp.statusCode}): '
          '${utf8.decode(resp.bodyBytes)}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    return data['voice_id'] as String;
  }

  Future<List<int>> synthesize({
    required String voiceId,
    required String text,
  }) async {
    final uri = Uri.parse('$_base/text-to-speech/$voiceId');
    final resp = await http.post(
      uri,
      headers: {
        'xi-api-key': apiKey,
        'Content-Type': 'application/json',
        'Accept': 'audio/mpeg',
      },
      body: utf8.encode(jsonEncode({
        'text': text,
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.8,
          'style': 0.0,
          'use_speaker_boost': true,
        },
      })),
    );

    if (resp.statusCode != 200) {
      throw HttpException(
          'Дуу нийлэгжүүлэх алдаа (${resp.statusCode}): '
          '${utf8.decode(resp.bodyBytes)}');
    }
    return resp.bodyBytes;
  }

  Future<void> deleteVoice(String voiceId) async {
    await http.delete(
      Uri.parse('$_base/voices/$voiceId'),
      headers: {'xi-api-key': apiKey},
    );
  }
}
