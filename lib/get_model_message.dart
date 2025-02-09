import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:math_llm_ui/models/chat_conversation_model.dart';

class GetModelMessage {
  static const String apiUrl = 'http://127.0.0.1:8000/generate';
  static Future<Map<String, dynamic>> sendPrompt(String prompt) async {
    print('Sending prompt: $prompt'); // Log the prompt being sent
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );
      if (response.statusCode == 200) {
        var decodedResponse = jsonDecode(response.body);
        print(
            'Response body: $decodedResponse'); // Log the successful response body
        return decodedResponse;
      } else {
        print(
            'Error: ${response.statusCode}, ${response.body}'); // Log the error response
        return {};
      }
    } catch (e) {
      print('Exception occurred: ${e.toString()}'); // Log any exceptions
      return {};
    }
  }

  static Future<String> sendPromptFormat(String prompt) async {
    print(
        'Formatting prompt response for: $prompt'); // Log the prompt being formatted
    Map<String, dynamic> response = await sendPrompt(prompt);

    if (response.isNotEmpty && response.containsKey("choices")) {
      try {
        String content =
            (response["choices"][0]["message"]["content"] as String)
                .replaceAll("<|question_end|>Answer:", "")
                .trim();
        print(
            'Formatted response content: $content'); // Log the formatted response
        return content;
      } catch (e) {
        print(
            'Error extracting content: ${e.toString()}'); // Log extraction errors
        return '';
      }
    } else {
      print(
          'No response received to format.'); // Log if no response was received
      return '';
    }
  }

  static Future<ChatConversationModel> generateResponse(String request) async {
    print(
        'Generating response for request: $request'); // Log the request being processed
    String resp = await sendPromptFormat(request);

    if (resp.isNotEmpty) {
      var chatModelData = {
        "choices": [
          {"text": resp, "index": 1, "finish_reason": "completed"}
        ]
      };
      print(
          'Generated ChatConversationModel data: $chatModelData'); // Log the model data
      return ChatConversationModel.fromJson(chatModelData);
    } else {
      print('No response generated.'); // Log if no response was generated
      return ChatConversationModel.fromJson({"choices": []});
    }
  }
}
