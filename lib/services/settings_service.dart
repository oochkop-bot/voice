import 'package:shared_preferences/shared_preferences.dart';

/// Тохиргоо болон API түлхүүрүүдийг утсан дээр хадгалах.
class SettingsService {
  static const _kOpenAiKey = 'openai_api_key';
  static const _kElevenKey = 'eleven_api_key';
  static const _kVoiceId = 'voice_id';
  static const _kVoiceName = 'voice_name';
  static const _kPersona = 'persona';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String?> get openAiKey async => (await _prefs).getString(_kOpenAiKey);
  Future<void> setOpenAiKey(String v) async =>
      (await _prefs).setString(_kOpenAiKey, v.trim());

  Future<String?> get elevenKey async => (await _prefs).getString(_kElevenKey);
  Future<void> setElevenKey(String v) async =>
      (await _prefs).setString(_kElevenKey, v.trim());

  /// ElevenLabs-аас буцаж ирсэн хуулбарласан хоолойн ID.
  Future<String?> get voiceId async => (await _prefs).getString(_kVoiceId);
  Future<void> setVoiceId(String v) async =>
      (await _prefs).setString(_kVoiceId, v);

  Future<String?> get voiceName async => (await _prefs).getString(_kVoiceName);
  Future<void> setVoiceName(String v) async =>
      (await _prefs).setString(_kVoiceName, v);

  /// LLM-д өгөх "зан төлөв / өнгө аяс"-ын зааварчилгаа.
  Future<String> get persona async =>
      (await _prefs).getString(_kPersona) ??
      'Чи найрсаг, эелдэг монгол хүн шиг ярь. Богино, ойлгомжтой хариул.';
  Future<void> setPersona(String v) async =>
      (await _prefs).setString(_kPersona, v);

  Future<bool> get isConfigured async {
    final ok = await openAiKey;
    final ek = await elevenKey;
    final vid = await voiceId;
    return (ok != null && ok.isNotEmpty) &&
        (ek != null && ek.isNotEmpty) &&
        (vid != null && vid.isNotEmpty);
  }
}
