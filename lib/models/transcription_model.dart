/// Data model for the Groq Whisper transcription API response.
///
/// Example response:
/// ```json
/// { "text": "Hello everyone." }
/// ```
class TranscriptionModel {
  const TranscriptionModel({required this.text});

  final String text;

  /// Parses the JSON body returned by the Groq Whisper endpoint.
  factory TranscriptionModel.fromJson(Map<String, dynamic> json) {
    final text = json['text'];

    if (text is! String || text.trim().isEmpty) {
      throw const FormatException('Transcription response is missing a valid "text" field.');
    }

    return TranscriptionModel(text: text.trim());
  }

  Map<String, dynamic> toJson() => {'text': text};
}
