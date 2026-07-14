/// Data model for the Groq Whisper transcription API response.
///
/// Example `verbose_json` response:
/// ```json
/// {
///   "task": "transcribe",
///   "language": "hi",
///   "text": "नमस्ते दुनिया"
/// }
/// ```
class TranscriptionModel {
  const TranscriptionModel({
    required this.text,
    this.detectedLanguage,
  });

  final String text;

  /// ISO 639-1 code detected by Whisper (e.g. `hi`, `ta`, `en`).
  final String? detectedLanguage;

  /// Parses the JSON body returned by the Groq Whisper endpoint.
  factory TranscriptionModel.fromJson(Map<String, dynamic> json) {
    final text = json['text'];

    if (text is! String || text.trim().isEmpty) {
      throw const FormatException(
        'Transcription response is missing a valid "text" field.',
      );
    }

    final language = json['language'];
    return TranscriptionModel(
      text: text.trim(),
      detectedLanguage: language is String ? language : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        if (detectedLanguage != null) 'language': detectedLanguage,
      };
}
