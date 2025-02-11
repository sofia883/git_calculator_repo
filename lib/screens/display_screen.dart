import 'package:calculator_app/common_imports.dart';
class CalculatorDisplay extends StatefulWidget {
  final String text;
  final double maxFontSize;
  final Color textColor;
  final bool
      isUserInput; // New parameter to differentiate between user input and answer

  const CalculatorDisplay({
    Key? key,
    required this.text,
    this.maxFontSize = 60,
    required this.textColor,
    this.isUserInput = true, // Default to true, indicating it's user input
  }) : super(key: key);

  @override
  _CalculatorDisplayState createState() => _CalculatorDisplayState();
}

class _CalculatorDisplayState extends State<CalculatorDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  bool _cursorVisible = true;
  double fontSize = 60;
  static const double minFontSize = 30;

  @override
  void initState() {
    super.initState();
    if (widget.isUserInput) {
      _cursorController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 500),
      )..repeat(reverse: true);
      _cursorController.addListener(() {
        setState(() {
          _cursorVisible = _cursorController.value > 0.5;
        });
      });
    }
  }

  @override
  void dispose() {
    if (widget.isUserInput) {
      _cursorController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth - 40;
        double currentFontSize = widget.maxFontSize;
        double textWidth = double.infinity; // Initialize textWidth

        // Determine text to display
        final displayText =
            widget.text.isEmpty && widget.isUserInput ? '0' : widget.text;

        do {
          final textStyle = TextStyle(
            fontSize: currentFontSize,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
          );

          final textPainter = TextPainter(
            text: TextSpan(text: displayText, style: textStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(minWidth: 0, maxWidth: double.infinity);

          textWidth = textPainter.width;
          if (textWidth > maxWidth) {
            currentFontSize -= 1;
          }

          if (currentFontSize < minFontSize) {
            currentFontSize = minFontSize;
            break;
          }
        } while (textWidth > maxWidth);

        return Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    displayText,
                    style: TextStyle(
                        fontSize: currentFontSize,
                        // fontWeight: FontWeight.bold,
                        color: widget.textColor),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              if (widget.isUserInput &&
                  displayText != '0') // Show cursor only if there's user input
                SizedBox(
                  width: currentFontSize * 0.2,
                  child: _cursorVisible
                      ? Text(
                          '|',
                          style: TextStyle(
                            fontSize: currentFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        )
                      : Container(),
                ),
            ],
          ),
        );
      },
    );
  }
}
