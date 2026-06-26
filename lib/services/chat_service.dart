import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Асуултад хариулдаг ухаалаг хэсэг (OpenAI Chat).
class ChatService {
  final String apiKey;
  ChatService(this.apiKey);

  /// Яриа түүхтэйгээр асуултад монголоор хариулна.
  /// [history] = өмнөх солилцоо, [persona] = өнгө аяс/зан төлөв.
  Future<String> answer({
    required String question,
    required String persona,
    List<Map<String, String>> history = const [],
  }) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content':
            'Чи гар утасны дуут туслах. Заавал МОНГОЛ хэлээр, ярианы '
            'хэлбэрээр (чанга яригдахаар) хариул. Хариулт богино, '
            'байгалийн, 1-3 өгүүлбэр байг. $persona'
      },
      ...history,
      {'role': 'user', 'content': question},
    ];

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json; charset=utf-8',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 300,
      }),
    );

    if (resp.statusCode != 200) {
      throw HttpException(
          'Chat алдаа (${resp.statusCode}): ${utf8.decode(resp.bodyBytes)}');
    }
    final data = jsonDecode(utf8.decode(resp.bodyBytes));
    return (data['choices'][0]['message']['content'] as String).trim();
  }
}
