import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumbmela_multilingual/screens/home_screen.dart';
import 'package:kumbmela_multilingual/services/speech_service.dart';

/// Lightweight fake so widget tests do not touch the real microphone or API.
class _FakeSpeechService extends SpeechService {
  @override
  Future<bool> requestMicrophonePermission() async => true;

  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('Home screen renders core controls', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(speechService: _FakeSpeechService()),
      ),
    );

    expect(find.text('Speech to Text'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('Transcription will appear here…'), findsOneWidget);
  });
}
