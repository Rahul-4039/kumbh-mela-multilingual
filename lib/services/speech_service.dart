import 'dart:io';

import 'package:dio/dio.dart';
import 'package:kumbmela_multilingual/constants.dart';
import 'package:kumbmela_multilingual/models/speech_language.dart';
import 'package:kumbmela_multilingual/models/transcription_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Typed exception for all speech-related failures.
class SpeechServiceException implements Exception {
  SpeechServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Handles microphone permissions, audio recording, and Groq API uploads.
///
/// All network and recording logic lives here so the UI layer stays thin.
class SpeechService {
  SpeechService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final AudioRecorder _recorder = AudioRecorder();

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Returns true when the user has granted microphone access.
  Future<bool> hasMicrophonePermission() async {
    return Permission.microphone.isGranted;
  }

  /// Requests microphone permission and returns whether it was granted.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ---------------------------------------------------------------------------
  // Recording — saves audio locally as .m4a (AAC)
  // ---------------------------------------------------------------------------

  /// Starts recording to a temporary .m4a file and returns its path.
  Future<String> startRecording() async {
    final granted = await requestMicrophonePermission();
    if (!granted) {
      throw SpeechServiceException(
        'Microphone permission denied. Enable it in device settings.',
      );
    }

    if (await _recorder.isRecording()) {
      throw SpeechServiceException('A recording is already in progress.');
    }

    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // AAC (.m4a) is widely supported by Groq Whisper and mobile platforms.
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    return filePath;
  }

  /// Stops the active recording and validates the output file.
  Future<String> stopRecording() async {
    final path = await _recorder.stop();

    if (path == null || path.isEmpty) {
      throw SpeechServiceException(
        'Recording failed. No audio file was created.',
      );
    }

    await _validateRecordingFile(path);
    return path;
  }

  /// Ensures the recorded file exists and is not effectively empty.
  Future<void> _validateRecordingFile(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw SpeechServiceException('Recording file was not found.');
    }

    final size = await file.length();
    if (size < AppConstants.minRecordingBytes) {
      throw SpeechServiceException(
        'Recording is empty. Please speak into the microphone and try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Groq Whisper API — multipart/form-data upload
  // ---------------------------------------------------------------------------

  /// Uploads [filePath] to Groq and returns the parsed transcription.
  ///
  /// When [language] is [SpeechLanguage.autoDetect], Whisper detects the
  /// spoken language and transcribes in native script (not English translation).
  /// Pass a specific [SpeechLanguage] to force Hindi, Tamil, etc.
  Future<TranscriptionModel> transcribeAudio(
    String filePath, {
    SpeechLanguage language = SpeechLanguage.autoDetect,
  }) async {
    _ensureApiKeyConfigured();
    await _validateRecordingFile(filePath);

    final fileName = filePath.split(Platform.pathSeparator).last;

    // Build multipart body required by the Groq Whisper endpoint.
    // `/audio/transcriptions` keeps the original language.
    // `/audio/translations` would convert everything to English — never use that.
    final formMap = <String, dynamic>{
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'model': AppConstants.whisperModel,
      'response_format': AppConstants.responseFormat,
      'temperature': AppConstants.transcriptionTemperature,
      // Native-script prompt steers Whisper away from English translation.
      'prompt': language.promptHint,
    };

    // Omit `language` for auto-detect; send ISO 639-1 code when user picks one.
    if (!language.isAutoDetect) {
      formMap['language'] = language.code;
    }

    final formData = FormData.fromMap(formMap);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConstants.transcriptionUrl,
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer ${AppConstants.groqApiKey}'},
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final data = response.data;
      if (data == null) {
        throw SpeechServiceException('API returned an empty response body.');
      }

      return TranscriptionModel.fromJson(data);
    } on DioException catch (error) {
      throw SpeechServiceException(_mapDioError(error));
    } on FormatException catch (error) {
      throw SpeechServiceException('Invalid API response: ${error.message}');
    }
  }

  /// Maps Dio errors to user-friendly messages.
  String _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'No internet connection. Please check your network and try again.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        final body = error.response?.data;
        return 'API failure (${status ?? 'unknown'}): $body';
      default:
        return 'Transcription failed: ${error.message ?? 'Unknown error'}';
    }
  }

  void _ensureApiKeyConfigured() {
    const placeholder = 'YOUR_API_KEY_HERE';
    if (AppConstants.groqApiKey.isEmpty ||
        AppConstants.groqApiKey == placeholder) {
      throw SpeechServiceException(
        'API key is not configured. Update lib/secrets.dart with your Groq key.',
      );
    }
  }

  /// Releases the underlying audio recorder resources.
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
