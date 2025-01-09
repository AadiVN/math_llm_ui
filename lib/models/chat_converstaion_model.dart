import 'package:math_llm_ui/entities/chat_conversation_data_entity.dart';
import 'package:math_llm_ui/entities/chat_converstaion_entity.dart';
import 'package:math_llm_ui/models/chat_conversation_data.dart';

class ChatConversationModel extends ChatConversationEntity {
  ChatConversationModel(
    final String? id,
    final List<ChatConversationDataEntity>? choices,
  ) : super(choices: choices, id: id);

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final chatConversationMessageItem = json['choices'] as List;

    List<ChatConversationDataEntity> choices = chatConversationMessageItem
        .map((messageItem) => ChatConversationData.fromJson(messageItem))
        .toList();

    return ChatConversationModel(json['id'], choices);
  }
}
