import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Яриаг текст болгож хувиргах (OpenAI Whisper).
class SttService {
  final String apiKey;
  SttService(this.apiKey);

  /// Аудио файлыг монгол текст болгоно.
  Future<String> transcribe(String filePath) async {
    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'mn'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw HttpException(
          'STT алдаа (${resp.statusCode}): ${utf8.decode(resp.bodyBytes)}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    return (data['text'] as String).trim();
  }
}
