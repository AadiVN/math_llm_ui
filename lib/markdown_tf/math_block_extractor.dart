import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathBlockExtractor extends StatelessWidget {
  final String latexString;

  MathBlockExtractor({required this.latexString});

  @override
  Widget build(BuildContext context) {
    // Define the pattern and extraction logic
    final blocks = extractTextAndMathBlocks(latexString);

    // Create a list of widgets to render text and LaTeX
    List<Widget> children = blocks.map((block) {
      if (block.isMath) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Math.tex(
            mathStyle: MathStyle.textCramped,
            block.content,
            textStyle:
                const TextStyle(fontSize: 24), // Standard size for inline math
          ),
        );
      } else {
        // Render regular text
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: MarkdownBody(data: block.content),
        );
      }
    }).toList();

    // Return a Row to align text and LaTeX inline
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        crossAxisAlignment:
            WrapCrossAlignment.center, // Align the baseline of text and math
        spacing: 4.0, // Horizontal spacing between items
        runSpacing: 4.0, // Vertical spacing for overflowed rows
        children: children,
      ),
    );
  }

  List<TextMathBlock> extractTextAndMathBlocks(String input) {
    // Pattern to match only inline math $ ... $
    final RegExp mathBlockPattern = RegExp(r'\$(.*?)\$');
    final List<TextMathBlock> blocks = [];

    // Split the input into text and math parts
    input.splitMapJoin(
      mathBlockPattern,
      onMatch: (match) {
        // Capture inline math $ ... $
        final content = match.group(1);
        if (content != null) {
          blocks.add(TextMathBlock(content: content, isMath: true));
        }
        return '';
      },
      onNonMatch: (nonMatch) {
        // Add the text block
        blocks.add(TextMathBlock(content: nonMatch, isMath: false));
        return '';
      },
    );

    return blocks;
  }
}

class TextMathBlock {
  final String content;
  final bool isMath;

  TextMathBlock({
    required this.content,
    required this.isMath,
  });
}
