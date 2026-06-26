import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ElevenLabs ашиглан хоолой хуулбарлах (clone) ба нийлэгжүүлэх (TTS).
class VoiceService {
  final String apiKey;
  VoiceService(this.apiKey);

  static const _base = 'https://api.elevenlabs.io/v1';

  /// 15-30 сек аудио файлаас тухайн хүний хоолойг хуулбарлаж,
  /// шинэ voice_id буцаана (Instant Voice Cloning).
  Future<String> cloneVoice({
    required String name,
    required String filePath,
    String description = 'Cowork апп-аар хуулбарласан хоолой',
  }) async {
    final uri = Uri.parse('$_base/voices/add');
    final request = http.MultipartRequest('POST', uri)
      ..headers['xi-api-key'] = apiKey
      ..fields['name'] = name
      ..fields['description'] = description
      ..files.add(await http.MultipartFile.fromPath('files', filePath));

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

  /// Текстийг хуулбарласан хоолойгоор дуу болгож, mp3 байтуудыг буцаана.
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
      body: jsonEncode({
        'text': text,
        // Олон хэл (монгол) дэмждэг загвар.
        'model_id': 'eleven_multilingual_v2',
        'voice_settings': {
          'stability': 0.5,
          'similarity_boost': 0.8,
          'style': 0.0,
          'use_speaker_boost': true,
        },
      }),
    );

    if (resp.statusCode != 200) {
      throw HttpException(
          'Дуу нийлэгжүүлэх алдаа (${resp.statusCode}): '
          '${utf8.decode(resp.bodyBytes)}');
    }
    return resp.bodyBytes;
  }

  /// Хуулбарласан хоолойг устгах (заавал биш).
  Future<void> deleteVoice(String voiceId) async {
    await http.delete(
      Uri.parse('$_base/voices/$voiceId'),
      headers: {'xi-api-key': apiKey},
    );
  }
}
