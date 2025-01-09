import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:math_llm_ui/entities/chat_message_entity.dart';
import 'package:math_llm_ui/features/chat/presentation/cubit/chat_conversation/chat_conversation_cubit.dart';
import 'package:math_llm_ui/widgets/chat_message_single_item.dart';
import 'package:math_llm_ui/widgets/example_widget.dart';
import 'package:math_llm_ui/widgets/left_nav_button_widget.dart';
import 'package:math_llm_ui/features/global/common/common.dart';
import 'package:math_llm_ui/features/global/const/app_const.dart';
import 'package:math_llm_ui/features/global/custom_text_field/custom_text_field.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ConversationPage extends StatefulWidget {
  const ConversationPage({Key? key}) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class Chat {
  String chatName;
  DateTime startDate;
  List<String> messages;

  Chat(this.chatName, this.startDate, this.messages);
}

class _ConversationPageState extends State<ConversationPage> {
  TextEditingController _messageController = TextEditingController();
  bool _isRequestProcessing = false;
  ScrollController _scrollController = ScrollController();
  bool _showDrawer = true;
  int messagesLength = 0;

  @override
  void initState() {
    _messageController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  final List<Chat> chatList = [];

  @override
  Widget build(BuildContext context) {
    if (_scrollController.hasClients) {
      Timer(
        Duration(milliseconds: 100),
        () => _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.decelerate),
      );
    }

    var drawer = Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      width: 300,
      decoration: BoxDecoration(
        boxShadow: glowBoxShadow,
        color: Colors.white, // Light background color
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  child:
                      Icon(Icons.view_sidebar_outlined, color: Colors.black87),
                  onTap: () => setState(() => _showDrawer = false),
                ),
                Spacer(),
                Icon(Icons.add, color: Colors.black87)
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _buildChatSections(),
              ),
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 0.50,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[300]),
          ),
          SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.delete_outline_outlined,
            textData: "Clear Conversation",
          ),
          SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.nightlight_outlined,
            textData: "Dark Mode",
          ),
          SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.ios_share_sharp,
            textData: "Update & FAQ",
          ),
          SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.exit_to_app,
            textData: "Log out",
          ),
          SizedBox(height: 10),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        _showDrawer
                            ? Container()
                            : Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  SizedBox(width: 20),
                                  Icon(Icons.add, color: Colors.black87),
                                  SizedBox(width: 10),
                                  InkWell(
                                    child: Icon(Icons.view_sidebar_outlined,
                                        color: Colors.black87),
                                    onTap: () =>
                                        setState(() => _showDrawer = true),
                                  ),
                                ],
                              ),
                        Expanded(
                          child: BlocBuilder<ChatConversationCubit,
                              ChatConversationState>(
                            builder: (context, chatConversationState) {
                              if (chatConversationState
                                  is ChatConversationLoaded) {
                                final chatMessages =
                                    chatConversationState.chatMessages;
                                messagesLength = chatMessages.length;

                                if (chatMessages.isEmpty) {
                                  return ExampleWidget(
                                    onMessageController: (message) {
                                      setState(() {
                                        _messageController.value =
                                            TextEditingValue(text: message);
                                      });
                                    },
                                  );
                                } else {
                                  return Container(
                                    child: ListView.builder(
                                      itemCount: _calculateListItemLength(
                                          messagesLength),
                                      controller: _scrollController,
                                      itemBuilder: (context, index) {
                                        if (index >= chatMessages.length) {
                                          return _responsePreparingWidget();
                                        } else {
                                          return ChatMessageSingleItem(
                                            chatMessage: chatMessages[index],
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }
                              }
                              return ExampleWidget(
                                onMessageController: (message) {
                                  setState(() {
                                    _messageController.value =
                                        TextEditingValue(text: message);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        CustomTextField(
                          isRequestProcessing: _isRequestProcessing,
                          textEditingController: _messageController,
                          onTap: () async {
                            _promptTrigger();
                          },
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                _showDrawer ? drawer : Container(),
              ],
            ),
          )
        ],
      ),
    );
  }

  List<Widget> _buildChatSections() {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    final lastWeek = today.subtract(Duration(days: 7));
    final lastMonth = DateTime(today.year, today.month - 1, today.day);
    final lastYear = DateTime(today.year - 1, today.month, today.day);

    List<Chat> yesterdayChats = [];
    List<Chat> weekChats = [];
    List<Chat> monthChats = [];
    List<Chat> yearChats = [];

    for (var chat in chatList) {
      if (chat.startDate.isAfter(yesterday)) {
        yesterdayChats.add(chat);
      } else if (chat.startDate.isAfter(lastWeek)) {
        weekChats.add(chat);
      } else if (chat.startDate.isAfter(lastMonth)) {
        monthChats.add(chat);
      } else if (chat.startDate.isAfter(lastYear)) {
        yearChats.add(chat);
      }
    }

    List<Widget> sections = [];

    if (yesterdayChats.isNotEmpty) {
      sections.add(_buildSection('Yesterday', yesterdayChats));
    }
    if (weekChats.isNotEmpty) {
      sections.add(_buildSection('Previous 7 Days', weekChats));
    }
    if (monthChats.isNotEmpty) {
      sections.add(_buildSection('Previous Month', monthChats));
    }
    if (yearChats.isNotEmpty) {
      sections.add(_buildSection('Previous Year', yearChats));
    }

    return sections;
  }

  Widget _buildSection(String title, List<Chat> chats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
        Column(
          children: chats
              .map((chat) => ListTile(
                    title: Text(
                      chat.chatName,
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  int _calculateListItemLength(int length) {
    return _isRequestProcessing ? length + 1 : length;
  }

  Widget _responsePreparingWidget() {
    return Container(
      height: 60,
      child: Image.asset("assets/loading_response.gif"),
    );
  }

  void _promptTrigger() {
    if (_messageController.text.isEmpty) {
      return;
    }

    final humanChatMessage = ChatMessageEntity(
      messageId: ChatGptConst.Human,
      queryPrompt: _messageController.text,
    );

    BlocProvider.of<ChatConversationCubit>(context)
        .chatConversation(
            chatMessage: humanChatMessage,
            onCompleteReqProcessing: (isRequestProcessing) {
              setState(() {
                _isRequestProcessing = isRequestProcessing;
              });
            })
        .then((value) {
      setState(() {
        _messageController.clear();
      });
      if (_scrollController.hasClients) {
        Timer(
          Duration(milliseconds: 100),
          () => _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 500),
              curve: Curves.decelerate),
        );
      }
    });
  }
}
