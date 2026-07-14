class ChatResponse {
  final String responseText;
  final String? audioUrl;

  ChatResponse({
    required this.responseText,
    this.audioUrl,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      responseText: json["responseText"],
      audioUrl: json["audioUrl"],
    );
  }
}