import 'secrets.dart';

/// Application-wide constants.
///
/// API credentials are loaded from [Secrets] (see secrets.example.dart).
/// Never hardcode keys directly in service or UI files.
abstract final class AppConstants {
  /// Groq API key — sourced from the local, gitignored secrets file.
  static const String groqApiKey = Secrets.groqApiKey;

  /// Groq OpenAI-compatible Whisper transcription endpoint.
  static const String transcriptionUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  /// Whisper model identifier supported by Groq.
  static const String whisperModel = 'whisper-large-v3-turbo';

  /// Expected JSON response format from the API.
  static const String responseFormat = 'json';

  /// Minimum valid recording size in bytes (~1 KB guard against silence).
  static const int minRecordingBytes = 1024;
}
