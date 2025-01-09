import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

import 'package:math_llm_ui/app_const.dart';
import 'package:math_llm_ui/entities/chat_message_entity.dart';
import 'package:math_llm_ui/get_model_message.dart';
import 'package:math_llm_ui/markdown_tf/format_markdown.dart';
import 'package:math_llm_ui/widgets/chat_message_single_item.dart';
import 'package:math_llm_ui/widgets/example_widget.dart';
import 'package:math_llm_ui/widgets/left_nav_button_widget.dart';
import 'package:math_llm_ui/widgets/markdown_text_input.dart';
import 'package:uuid/uuid.dart';

import 'theme/style.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({Key? key}) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class Chat {
  String id; // Unique identifier for the chat
  String chatName; // Name of the chat
  DateTime startDate; // Start date of the chat
  List<ChatMessageEntity> messages; // List of messages in the chat

  Chat(
    this.id,
    this.chatName,
    this.startDate,
    this.messages,
  );
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isRequestProcessing = false; // Flag to indicate request status
  final ScrollController _scrollController = ScrollController();
  bool _showDrawer = true; // Drawer visibility

  // Store the ID and index of the currently selected chat
  String currentChatId = "";
  int currentChatIdx = 0;

  bool newChat = false; // Indicates if a new chat is being created

  List<Chat> chatList = [];

  bool editing = false;

  List<ImageProvider> images = []; // List to store chats

  List<String> get chatIdList => chatList.map((e) => e.id).toList();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {}); // Rebuild when the message input changes
    });
    newChat = chatList.isEmpty; // Set newChat based on chatList state
  }

  @override
  void dispose() {
    _messageController.dispose(); // Dispose of the controller
    _scrollController.dispose(); // Dispose of the scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Autoscroll to the bottom when messages are added
    if (_scrollController.hasClients) {
      Timer(
        const Duration(milliseconds: 100),
        () => _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.decelerate,
        ),
      );
    }

    // Function to make a new chat
    void makeNew() {
      _messageController.clear();
      setState(() => newChat = true);
    }

    var drawer = Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      width: 300,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  child: Icon(Icons.view_sidebar_outlined, color: Colors.white),
                  onTap: () => setState(() => _showDrawer = false),
                ),
                const Spacer(),
                InkWell(
                  onTap: makeNew,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: _buildChatSections(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 0.50,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.delete_outline_outlined,
            textData: "Clear Conversation",
          ),
          const SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.nightlight_outlined,
            textData: "Dark Mode",
          ),
          const SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.ios_share_sharp,
            textData: "Update & FAQ",
          ),
          const SizedBox(height: 10),
          LeftNavButtonWidget(
            iconData: Icons.exit_to_app,
            textData: "Log out",
          ),
          const SizedBox(height: 10),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color.fromRGBO(52, 53, 64, 1),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 200),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(52, 53, 64, 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            _showDrawer
                                ? Container()
                                : Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      const SizedBox(width: 20),
                                      InkWell(
                                        onTap: makeNew,
                                        child: Icon(Icons.add,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(width: 10),
                                      InkWell(
                                        child: Icon(Icons.view_sidebar_outlined,
                                            color: Colors.white),
                                        onTap: () =>
                                            setState(() => _showDrawer = true),
                                      ),
                                    ],
                                  ),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  var chatMessages = newChat
                                      ? []
                                      : chatList[currentChatIdx].messages;

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
                                    return ListView.builder(
                                      itemCount: _calculateListItemLength(
                                          chatMessages.length),
                                      controller: _scrollController,
                                      itemBuilder: (context, index) {
                                        if (index >= chatMessages.length) {
                                          return Center(
                                              child:
                                                  _responsePreparingWidget());
                                        } else {
                                          return ChatMessageSingleItem(
                                            chatMessage: chatMessages[index],
                                          );
                                        }
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Stack the message input at the bottom within the Expanded
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildMessageInput(),
                      ),
                    ],
                  ),
                ),
                _showDrawer ? drawer : Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the message input area.
  Widget _buildMessageInput() {
    return Container(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 20, left: 150, right: 150),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,

        // controller _messageController
        children: [
          Expanded(
            child: CustomMarkdownTextInput(
                actions: MarkdownType.values,
                (text) => setState(() => _messageController.text = text),
                _messageController.text,
                submit: _buildSendButton(),
                images: images),
          )
        ],
      ),
    );
  }

  /// Builds the send button for sending messages.
  Widget _buildSendButton() {
    return InkWell(
      onTap: _messageController.text.isEmpty
          ? null
          : () async {
              // If the message is empty, do not proceed
              if (_messageController.text.isEmpty) return;

              setState(() {
                _isRequestProcessing = true;
              });

              final humanChatMessage = ChatMessageEntity(
                messageId: ChatGptConst.Human,
                queryPrompt: _messageController.text,
              );
              if (newChat) {
                _createNewChat(humanChatMessage);
              } else {
                _appendHumanMessage(humanChatMessage);
              }

              final response = await GetModelMessage.generateResponse(
                  humanChatMessage.queryPrompt ?? "");

              final chatMessageResponse = ChatMessageEntity(
                messageId: ChatGptConst.AIBot,
                promptResponse: response.choices!.first.text,
              );

              // Handle chat creation and message appending
              _appendBotMessage(chatMessageResponse);
              setState(() {
                _isRequestProcessing = false;
              });
              _messageController.clear();
            },
      child: Icon(
        Feather.send,
        color: _messageController.text.isEmpty
            ? Colors.grey.withOpacity(.4)
            : Colors.grey,
      ),
    );
  }

  /// Create a new chat and append messages to it.
  void _createNewChat(ChatMessageEntity humanChatMessage) {
    Chat newChatInstance = Chat(
      Uuid().v4(),
      "New Chat",
      DateTime.now(),
      [],
    );

    chatList.add(newChatInstance);
    currentChatId = newChatInstance.id;
    currentChatIdx = chatIdList.indexOf(currentChatId);
    print(currentChatId);
    print(currentChatIdx);
    newChat = false;

    // Append messages to the newly created chat
    chatList[currentChatIdx].messages.add(humanChatMessage);
    setState(() {});
  }

  /// Append messages to the current chat.
  void _appendHumanMessage(ChatMessageEntity humanChatMessage) {
    chatList[currentChatIdx].messages.add(humanChatMessage);
    setState(() {});
  }

  void _appendBotMessage(ChatMessageEntity chatMessageResponse) {
    chatList[currentChatIdx].messages.add(chatMessageResponse);
    setState(() {
      _isRequestProcessing = false;
    });
  }

  /// Prepare widget to indicate response is being generated.
  Widget _responsePreparingWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: colorDarkGray,
            ),
            child: const CircularProgressIndicator(
                strokeWidth: 3, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text("Processing...", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  /// Calculate the length of list items.
  int _calculateListItemLength(int messageLength) {
    return _isRequestProcessing ? messageLength + 1 : messageLength;
  }

  /// Builds chat sections for the drawer.
  List<Widget> _buildChatSections() {
    return List.generate(chatList.length, (index) {
      final chat = chatList[index];
      return InkWell(
        onDoubleTap: () => setState(() => editing = true),
        child: ListTile(
          title: (editing && (currentChatId == chat.id))
              ? Form(
                  key: GlobalKey<FormState>(),
                  child: TextFormField(
                    initialValue: chat.chatName,
                    onFieldSubmitted: (value) => setState(() {
                      chat.chatName = value;
                      editing = false;
                    }),
                  ),
                )
              : Text(chat.chatName,
                  style: const TextStyle(color: Colors.white)),
          onTap: () {
            setState(() {
              currentChatId = chat.id;
              currentChatIdx = chatIdList.indexOf(currentChatId);
              newChat = false;
            });
          },
        ),
      );
    });
  }
}
