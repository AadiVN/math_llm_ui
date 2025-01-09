import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:web/web.dart' as web;

import '../markdown_tf/format_markdown.dart';
import '../markdown_tf/math_block_extractor.dart';

/// Widget with markdown buttons
class CustomMarkdownTextInput extends StatefulWidget {
  /// Callback called when text changed
  final Function onTextChanged;

  /// Initial value you want to display
  final String initialValue;

  /// Validator for the TextFormField
  final String? Function(String? value)? validators;

  /// String displayed at hintText in TextFormField
  final String? label;

  /// Change the text direction of the input (RTL / LTR)
  final TextDirection textDirection;

  /// The maximum of lines that can be display in the input
  final int? maxLines;

  /// List of action the component can handle
  final List<MarkdownType> actions;

  /// List of custom action buttons
  final List<ActionButton> optionnalActionButtons;

  /// Optional controller to manage the input
  final TextEditingController? controller;

  /// Overrides input text style
  final TextStyle? textStyle;

  /// If you prefer to use the dialog to insert links, you can choose to use the markdown syntax directly by setting [insertLinksByDialog] to false. In this case, the selected text will be used as label and link.
  /// Default value is true.
  final bool insertLinksByDialog;

  ///Optional focusNode, the Widget creates it's own if not provided
  final FocusNode? focusNode;

  /// If you prefer to use the dialog to insert image, you can choose to use the markdown syntax directly by setting [insertImageByDialog] to false. In this case, the selected text will be used as label and link.
  /// Default value is true.
  final bool insertImageByDialog;

  /// InputDecoration for the text input of the link dialog
  final InputDecoration? linkDialogLinkDecoration;

  /// InputDecoration for the link input of the link dialog
  final InputDecoration? linkDialogTextDecoration;

  /// InputDecoration for the text input of the image dialog
  final InputDecoration? imageDialogLinkDecoration;

  final Widget submit;

  /// InputDecoration for the link input of the image dialog
  final InputDecoration? imageDialogTextDecoration;

  /// Custom text for cancel button in dialogs
  final String? customCancelDialogText;

  /// Custom text for submit button in dialogs
  final String? customSubmitDialogText;

  final List<ImageProvider> images;

  /// Constructor for [CustomMarkdownTextInput]
  CustomMarkdownTextInput(this.onTextChanged, this.initialValue,
      {this.label = '',
      this.validators,
      this.textDirection = TextDirection.ltr,
      this.maxLines = 5,
      this.actions = const [
        MarkdownType.bold,
        MarkdownType.italic,
        MarkdownType.title,
        MarkdownType.link,
        MarkdownType.list
      ],
      this.textStyle,
      this.controller,
      required this.submit,
      required this.images,
      this.insertLinksByDialog = true,
      this.insertImageByDialog = true,
      this.focusNode,
      this.linkDialogLinkDecoration,
      this.linkDialogTextDecoration,
      this.imageDialogLinkDecoration,
      this.imageDialogTextDecoration,
      this.customCancelDialogText,
      this.customSubmitDialogText,
      this.optionnalActionButtons = const []});

  @override
  _MarkdownTextInputState createState() =>
      _MarkdownTextInputState(controller ?? TextEditingController());
}

class _MarkdownTextInputState extends State<CustomMarkdownTextInput> {
  ImageProvider? _isHovering = null;
  final TextEditingController _controller;
  TextSelection textSelection =
      const TextSelection(baseOffset: 0, extentOffset: 0);
  late final FocusNode focusNode;

  late DropzoneViewController ctl;

  _MarkdownTextInputState(this._controller);

  void onTap(MarkdownType type,
      {int titleSize = 1, String? link, String? selectedText, String? math}) {
    final basePosition = textSelection.baseOffset;
    var noTextSelected =
        (textSelection.baseOffset - textSelection.extentOffset) == 0;

    var fromIndex = min(textSelection.baseOffset, textSelection.extentOffset);
    var toIndex = max(textSelection.extentOffset, textSelection.baseOffset);

    final result = FormatMarkdown.convertToMarkdown(
        type, _controller.text, fromIndex, toIndex,
        titleSize: titleSize,
        link: link,
        keyboardData: math,
        selectedText:
            selectedText ?? _controller.text.substring(fromIndex, toIndex));

    _controller.value = _controller.value.copyWith(
        text: result.data,
        selection:
            TextSelection.collapsed(offset: basePosition + result.cursorIndex));

    if (noTextSelected) {
      _controller.selection = TextSelection.collapsed(
          offset: _controller.selection.end - result.replaceCursorIndex);
      focusNode.requestFocus();
    }
  }

  @override
  void initState() {
    focusNode = widget.focusNode ?? FocusNode();
    _controller.text = widget.initialValue;
    _controller.addListener(() {
      if (_controller.selection.baseOffset != -1)
        textSelection = _controller.selection;
      widget.onTextChanged(_controller.text);
    });
    super.initState();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          child: DropzoneView(
            operation: DragOperation.all,
            onCreated: (controller) {
              ctl = controller;
            },
            onHover: () {
              print('Zone hovered');
            },
            onDropMultiple: (List<dynamic>? ev) {
              if (ev != null) {
                for (var e in ev) {
                  if (e is web.File) {
                    _addWebImage(e);
                  }
                }
              }
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
                color: Theme.of(context).colorScheme.secondary, width: 2),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          border: Border.fromBorderSide(BorderSide.none)),
                      height: 150,
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: <Widget>[
                          imageWidget(),
                          previewWidget(),
                          TextFormField(
                            focusNode: focusNode,
                            textInputAction: TextInputAction.newline,
                            maxLines: widget.maxLines,
                            controller: _controller,
                            textCapitalization: TextCapitalization.sentences,
                            validator: widget.validators != null
                                ? (value) => widget.validators!(value)
                                : null,
                            style: widget.textStyle ??
                                Theme.of(context).textTheme.bodyLarge,
                            // cursorColor: Theme.of(context).primaryColor,
                            textDirection: widget.textDirection,
                            decoration: InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.none),
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide.none),
                              // enabledBorder: UnderlineInputBorder(
                              //     borderSide: BorderSide(
                              //         color:
                              //             Theme.of(context).colorScheme.secondary)),
                              // focusedBorder: UnderlineInputBorder(
                              //     borderSide: BorderSide(
                              //         color:
                              //             Theme.of(context).colorScheme.secondary)),
                              hintText: widget.label,
                              hintStyle: const TextStyle(
                                  color: Color.fromRGBO(63, 61, 86, 0.5)),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                            top: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 2)),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                      ),
                      height: 44,
                      child: Material(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10)),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: actions(context),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 10,
              ),
              widget.submit
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> actions(BuildContext context) {
    return <Widget>[
      ...widget.actions.map((type) {
        if (type == MarkdownType.title) {
          return ExpandableNotifier(
            child: Expandable(
              key: Key('H#_button'),
              collapsed: ExpandableButton(
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'H#',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              expanded: Container(
                color: Colors.white10,
                child: Row(
                  children: [
                    for (int i = 1; i <= 6; i++)
                      InkWell(
                        key: Key('H${i}_button'),
                        onTap: () => onTap(MarkdownType.title, titleSize: i),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            'H$i',
                            style: TextStyle(
                                fontSize: (18 - i).toDouble(),
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ExpandableButton(
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.close,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (type == MarkdownType.link || type == MarkdownType.image) {
          return _basicInkwell(
            type,
            customOnTap: (type == MarkdownType.link
                    ? !widget.insertLinksByDialog
                    : !widget.insertImageByDialog)
                ? null
                : () async {
                    var text = _controller.text.substring(
                        textSelection.baseOffset, textSelection.extentOffset);

                    var textController = TextEditingController()..text = text;
                    var linkController = TextEditingController();

                    var color = Theme.of(context).colorScheme.secondary;

                    await _basicDialog(
                        textController, linkController, color, text, type);
                  },
          );
        } else if (type == MarkdownType.math) {
          return _basicInkwell(type, customOnTap: () async {
            await _mathDialog(type);
          });
        } else {
          return _basicInkwell(type);
        }
      }).toList(),
      ...widget.optionnalActionButtons.map((ActionButton optionActionButton) {
        return _basicInkwell(optionActionButton,
            customOnTap: optionActionButton.action);
      }).toList()
    ];
  }

  Container imageWidget() {
    return widget.images.isEmpty
        ? Container()
        : Container(
            padding: EdgeInsets.all(5),
            height: 100,
            child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: widget.images
                      .map((e) => InkWell(
                            onTap: () {
                              showDialog(
                                  barrierColor: Color.fromARGB(200, 0, 0, 0),
                                  builder: (ctx) => Container(
                                        color: Colors.transparent,
                                        height:
                                            MediaQuery.of(context).size.height,
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Stack(
                                          children: [
                                            Center(
                                              child: Dialog(
                                                insetPadding: EdgeInsets.zero,
                                                child: Image(
                                                  image: e,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                                right: 25,
                                                top: 25,
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () =>
                                                        Navigator.pop(ctx),
                                                    child: Icon(
                                                        color: Colors.white,
                                                        size: 24,
                                                        IconData(0xe16a,
                                                            fontFamily:
                                                                'MaterialIcons')),
                                                  ),
                                                ))
                                          ],
                                        ),
                                      ),
                                  context: context);
                            },
                            child: MouseRegion(
                              onEnter: (event) => setState(() {
                                _isHovering = e;
                              }),
                              onExit: (event) => setState(() {
                                _isHovering = null;
                              }),
                              child: Container(
                                height: 90,
                                width: 90,
                                margin: EdgeInsets.all(5),
                                child: Stack(
                                  clipBehavior: Clip
                                      .none, // Prevents the Stack from clipping its children
                                  children: [
                                    // Container with curved border and clipped image
                                    Container(
                                      height: 75,
                                      width: 75,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        image: DecorationImage(
                                          image: e,
                                          fit: BoxFit
                                              .cover, // Ensures the image fits within the curved border
                                        ),
                                      ),
                                    ),
                                    // Positioned cross icon with center aligned at the top-right corner of the image
                                    _isHovering == e
                                        ? Positioned(
                                            right:
                                                6, // Adjust half of the icon size to offset horizontally
                                            top:
                                                -7.5, // Adjust half of the icon size to offset vertically
                                            child: Tooltip(
                                              message: "Delete",
                                              child: InkWell(
                                                  onTap: () {
                                                    // Add onTap functionality if needed
                                                    widget.images.remove(e);
                                                    setState(() {});
                                                  },
                                                  child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.white,
                                                      radius: 12,
                                                      child: Icon(
                                                        IconData(0xe16a,
                                                            fontFamily:
                                                                'MaterialIcons'),
                                                        size: 18,
                                                        color: Colors.black,
                                                      ))),
                                            ),
                                          )
                                        : Container()
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                )));
  }

  Container previewWidget() {
    return _controller.text.isEmpty
        ? Container()
        : Container(
            margin: EdgeInsets.all(10),
            width: MediaQuery.of(context).size.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Preview",
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(
                  height: 5,
                ),
                MathBlockExtractor(
                  latexString: _controller.text,
                )
              ],
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                  left: BorderSide.none,
                  right: BorderSide.none,
                  top: BorderSide.none,
                  bottom: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2)),
              borderRadius: const BorderRadius.all(Radius.circular(0)),
            ),
          );
  }

  Widget _basicInkwell(dynamic item, {Function? customOnTap}) {
    Widget widgetToReturn = SizedBox.shrink();

    if (item is MarkdownType) {
      return InkWell(
        key: Key(item.key),
        onTap: () => customOnTap != null ? customOnTap() : onTap(item),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Icon(item.icon),
        ),
      );
    } else if (item is ActionButton) {
      return InkWell(
        onTap: item.action,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: item.widget,
        ),
      );
    }

    return widgetToReturn;
  }

  Future<void> _addWebImage(web.File file) async {
    final bytes = await ctl.getFileData(file); // Get file data
    print('Read bytes with length ${bytes.length}');
    final base64Image = 'data:${file.type};base64,${base64Encode(bytes)}';
    setState(() {
      widget.images.add(NetworkImage(base64Image)); // Add as NetworkImage
    });
    print('Web image added: ${file.name}');
  }

  Future<void> _mathDialog(
    MarkdownType type,
  ) async {
    MathFieldEditingController controller = MathFieldEditingController();
    return await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 100,
                  width: 900,
                  child: MathField(
                    controller: controller,
                    autofocus: true,
                  ),
                ),
              ],
            ),
            contentPadding: EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 12.0),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(widget.customCancelDialogText ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  var math =
                      controller.root.buildTeXString(cursorColor: Colors.black);
                  var updatedMath =
                      math.replaceAll(r"\textcolor{#000000}{\cursor}", "");
                  onTap(type, math: updatedMath);
                  Navigator.pop(context);
                },
                child: Text(widget.customSubmitDialogText ?? 'OK'),
              ),
            ],
          );
        });
  }

  Future<void> _basicDialog(
    TextEditingController textController,
    TextEditingController linkController,
    Color color,
    String text,
    MarkdownType type,
  ) async {
    var finalTextInputDecoration = type == MarkdownType.link
        ? widget.linkDialogTextDecoration
        : widget.imageDialogTextDecoration;
    var finalLinkInputDecoration = type == MarkdownType.link
        ? widget.linkDialogLinkDecoration
        : widget.imageDialogLinkDecoration;

    var textFocus = FocusNode();
    var linkFocus = FocusNode();

    return await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: textController,
                  decoration: finalTextInputDecoration ??
                      InputDecoration(
                        hintText: 'Example text',
                        label: Text('Text'),
                        labelStyle: TextStyle(color: color),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color, width: 2)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color, width: 2)),
                      ),
                  autofocus: text.isEmpty,
                  focusNode: textFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (value) {
                    textFocus.unfocus();
                    FocusScope.of(context).requestFocus(linkFocus);
                  },
                ),
                SizedBox(height: 10),
                TextField(
                  controller: linkController,
                  decoration: finalLinkInputDecoration ??
                      InputDecoration(
                        hintText: 'https://example.com',
                        label: Text('Link'),
                        labelStyle: TextStyle(color: color),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color, width: 2)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: color, width: 2)),
                      ),
                  autofocus: text.isNotEmpty,
                  focusNode: linkFocus,
                ),
              ],
            ),
            contentPadding: EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 12.0),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(widget.customCancelDialogText ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onTap(type,
                      link: linkController.text,
                      selectedText: textController.text);
                  Navigator.pop(context);
                },
                child: Text(widget.customSubmitDialogText ?? 'OK'),
              ),
            ],
          );
        });
  }
}
