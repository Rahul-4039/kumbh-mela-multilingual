import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kumbmela_multilingual/text-to-speech/services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController questionController = TextEditingController();
  final ApiService apiService = ApiService();
  final AudioPlayer player = AudioPlayer();

  String response = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enterprise AI Assistant"),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            const SizedBox(height: 20),

            TextField(
              controller: questionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Ask anything...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (questionController.text.trim().isEmpty) {
                    return;
                  }

                  final result = await apiService.sendMessage(
                    questionController.text,
                  );

                  setState(() {
                    response = result.responseText;
                  });

                  if (result.audioUrl != null) {
                    await player.setUrl(result.audioUrl!);
                    await player.play();
                  }
                },

                child: const Text("Send"),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Response",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(
                  response.isEmpty ? "No response yet." : response,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
