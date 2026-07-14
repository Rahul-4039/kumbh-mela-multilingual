import 'package:dio/dio.dart';
import '../models/chat_response.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
        baseUrl: "http://192.168.2.97:8000"
    ),
  );

  Future<ChatResponse> sendMessage(String message) async {
    final response = await _dio.post(
      "/chat",
      data: {
        "message": message,
      },
    );

    return ChatResponse.fromJson(response.data);
  }
}