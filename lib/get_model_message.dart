import 'dart:convert';
import 'package:http/http.dart';
import 'package:math_llm_ui/models/chat_converstaion_model.dart';

class GetModelMessage {
  static Future<Map<String, dynamic>> sendPrompt(String prompt) async {
    var client = Client();
    print('Sending prompt: $prompt'); // Log the prompt being sent
    try {
      Response response = await client.post(
        Uri.https(
            "admin-tpl--basic-inference-fastapi-app-dev.modal.run", "generate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"prompt": prompt}),
      );

      // Log the response status code
      print('Response status code: ${response.statusCode}');

      // Check for a successful response
      if (response.statusCode == 200) {
        var decodedResponse =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
    } finally {
      client.close();
      print('HTTP client closed.'); // Log the closure of the client
    }
  }

  static Future<String> sendPromptFormat(String prompt) async {
    print(
        'Formatting prompt response for: $prompt'); // Log the prompt being formatted
    Map<String, dynamic> response = await sendPrompt(prompt);

    if (response.isNotEmpty) {
      String content = (response["choices"][0]["message"]["content"] as String)
          .replaceAll("<|question_end|>Answer:", "");
      print(
          'Formatted response content: $content'); // Log the formatted response
      return content;
    } else {
      print(
          'No response received to format.'); // Log if no response was received
      return '';
    }
  }

  static Future<ChatConversationModel> generateResponse(String requests) async {
    print(
        'Generating response for request: $requests'); // Log the request being processed
    String resp = await sendPromptFormat(requests);

    if (resp.isNotEmpty) {
      var chatModelData = {
        "choices": [
          {"text": resp, 'index': 1, 'finish_reason': 'completed'}
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
