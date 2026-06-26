import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

/// Микрофоноор бичих, аудио тоглуулах хариуцсан хэсэг.
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  Future<bool> ensureMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> get isRecording => _recorder.isRecording();

  /// Бичлэг эхлүүлнэ. Файлын замыг буцаана.
  Future<String> startRecording({String fileName = 'rec.m4a'}) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
      ),
      path: path,
    );
    return path;
  }

  /// Бичлэг зогсооно. Бичигдсэн файлын замыг буцаана.
  Future<String?> stopRecording() async {
    return _recorder.stop();
  }

  Future<void> playFile(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> playBytesAsFile(List<int> bytes,
      {String fileName = 'reply.mp3'}) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$fileName');
    await f.writeAsBytes(bytes, flush: true);
    await playFile(f.path);
  }

  Future<void> stopPlayback() async => _player.stop();

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
