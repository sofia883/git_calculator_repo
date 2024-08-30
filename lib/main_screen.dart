import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;

class CalculationHistory {
  final String title;
  final String equation;
  final String result;

  CalculationHistory(
      {required this.title, required this.equation, required this.result});

  Map<String, dynamic> toJson() => {
        'title': title,
        'equation': equation,
        'result': result,
      };

  factory CalculationHistory.fromJson(Map<String, dynamic> json) =>
      CalculationHistory(
        title: json['title'],
        equation: json['equation'],
        result: json['result'],
      );
}

class Calculator extends StatefulWidget {
  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String _output = "";
  String _equation = "";
  bool _isDarkMode = true;
  String _currentTitle = "";
  List<CalculationHistory> _history = [];
  double _fontSize = 60.0;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  // ... [Previous methods remain unchanged]

  void _updateFontSize() {
    setState(() {
      if (_output.length > 8) {
        _fontSize = 60.0 - (_output.length - 8) * 2.0;
        _fontSize = _fontSize.clamp(15.0, 60.0); // Changed minimum to 15.0
      } else {
        _fontSize = 60.0;
      }
    });
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == "C") {
        _output = "";
        _equation = "";
        _fontSize = 60.0;
      } else if (buttonText == "=") {
        _equation = _output;
        try {
          var result = _evaluateExpression(_output);
          _output = result.toStringAsFixed(2);
          _addToHistory();
        } catch (e) {
          _output = "Error";
        }
      } else if (buttonText == "<") {
        if (_output.isNotEmpty) {
          _output = _output.substring(0, _output.length - 1);
        }
      } else {
        _output += buttonText;
      }
      _updateFontSize();
    });
  }

  void _scrollToEnd() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('history') ?? [];
    setState(() {
      _history = historyJson
          .map((item) => CalculationHistory.fromJson(jsonDecode(item)))
          .toList();
    });
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson =
        _history.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('history', historyJson);
  }

  void _addToHistory() {
    if (_currentTitle.isNotEmpty) {
      setState(() {
        _history.insert(
            0,
            CalculationHistory(
              title: _currentTitle,
              equation: _equation,
              result: _output,
            ));
        _currentTitle = "";
      });
      _saveHistory();
    }
  }

  double _evaluateExpression(String expression) {
    expression = expression.replaceAll('x', '*');
    expression = expression.replaceAll('÷', '/');

    List<String> tokens = expression.split(RegExp(r'(\+|\-|\*|\/)'));
    List<String> operators = expression
        .split(RegExp(r'[^+\-*/]+'))
        .where((s) => s.isNotEmpty)
        .toList();

    List<double> numbers = tokens.map((t) => double.tryParse(t) ?? 0).toList();

    // Perform multiplication and division first
    for (int i = 0; i < operators.length; i++) {
      if (operators[i] == '*' || operators[i] == '/') {
        double result = operators[i] == '*'
            ? numbers[i] * numbers[i + 1]
            : numbers[i] / numbers[i + 1];
        numbers[i] = result;
        numbers.removeAt(i + 1);
        operators.removeAt(i);
        i--;
      }
    }

    // Perform addition and subtraction
    double result = numbers[0];
    for (int i = 0; i < operators.length; i++) {
      if (operators[i] == '+') {
        result += numbers[i + 1];
      } else if (operators[i] == '-') {
        result -= numbers[i + 1];
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent resizing when keyboard opens
      body: _buildCalculatorUI(context, _isDarkMode),
    );
  }

  Widget _buildCalculatorUI(BuildContext context, bool isDark) {
    Color bgColor = isDark ? Color(0xFF17181A) : Color(0xFFF4F5F6);
    Color textColor = isDark ? Colors.white : Colors.black;
    Color buttonColor = isDark ? Color(0xFF2E2F38) : Color(0xFFE9E9EA);
    Color orangeColor = Color(0xFFFFA000);
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: topPadding, left: 6, right: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Enter title",
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: (value) => _currentTitle = value,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.history, color: textColor),
                  onPressed: _showHistory,
                ),
                IconButton(
                  icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: textColor),
                  onPressed: () {
                    setState(() {
                      _isDarkMode = !_isDarkMode;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: CalculatorDisplay(text: _output),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    _buildButtonRow(['C', '%', 'x'], buttonColor, textColor),
                    _buildButtonRow(['7', '8', '9'], buttonColor, textColor),
                    _buildButtonRow(['4', '5', '6'], buttonColor, textColor),
                    _buildButtonRow(
                        ['1', '2', '3'], buttonColor, textColor, orangeColor),
                    _buildButtonRow(['.', '0', '<'], buttonColor, textColor),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildButtonColumn(['÷', '+', '-'], buttonColor, textColor),
                    Container(
                      child: _buildButton('=', buttonColor, textColor),
                      height: 156,
                      width: 75,
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(
      List<String> buttons, Color buttonColor, Color textColor,
      [Color? specialColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons
            .map((button) => _buildButton(
                button,
                button == '=' ? (specialColor ?? buttonColor) : buttonColor,
                textColor))
            .toList(),
      ),
    );
  }

  Widget _buildButtonColumn(
      List<String> buttons, Color buttonColor, Color textColor) {
    return Column(
      children: buttons.map((button) {
        return Column(
          children: [
            _buildButton(button, buttonColor, textColor),
            SizedBox(height: 10), // Add spacing between buttons in the column
          ],
        );
      }).toList(),
    );
  }

  Widget _buildButton(String text, Color buttonColor, Color textColor) {
    return Container(
      width: 88,
      height: 75,
      child: Card(
        elevation: 3,
        shadowColor: Colors.white,
        shape: text == '='
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    45), // Rectangular shape with sharp corners
              )
            : const CircleBorder(), // Makes the button circular

        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: text == '=' ? Colors.orange : buttonColor,
            shape: text == '='
                ? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        45), // Rectangular shape with sharp corners
                  )
                : const CircleBorder(), // Makes the button circular
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 24,
              color: text == '=' ? Colors.white : textColor,
            ),
          ),
          onPressed: () => _onButtonPressed(text),
        ),
      ),
    );
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Calculation History"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text("${item.equation} = ${item.result}"),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text("Clear History"),
              onPressed: () {
                setState(() {
                  _history.clear();
                  _saveHistory();
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

class FadingText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const FadingText({Key? key, required this.text, required this.style})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _FadingTextPainter(text: text, style: style),
        );
      },
    );
  }
}

class _FadingTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;

  _FadingTextPainter({required this.text, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);

    final textWidth = textPainter.width;
    final fadeWidth = size.width * 0.2; // 20% of the width for fading

    if (textWidth <= size.width) {
      // If text fits, just paint it normally
      textPainter.paint(canvas, Offset(size.width - textWidth, 0));
    } else {
      // If text doesn't fit, we need to fade and clip
      final shader = ui.Gradient.linear(
        Offset.zero,
        Offset(fadeWidth, 0),
        [style.color!.withOpacity(0), style.color!],
      );

      final paint = Paint()..shader = shader;

      canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // Calculate the offset to ensure the last word is fully visible
      final lastWord = text.split(RegExp(r'[,\s]+')).last;
      final lastWordPainter = TextPainter(
        text: TextSpan(text: lastWord, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      final lastWordWidth = lastWordPainter.width;

      final visibleTextWidth = size.width - fadeWidth;
      final startX = -(textWidth - visibleTextWidth - lastWordWidth);

      textPainter.paint(canvas, Offset(startX, 0));

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CalculatorDisplay extends StatefulWidget {
  final String text;
  final double maxFontSize;

  const CalculatorDisplay({
    Key? key,
    required this.text,
    this.maxFontSize = 60,
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

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth - 40; // Left and right padding
        double currentFontSize = widget.maxFontSize;
        double textWidth;

        do {
          final textStyle = TextStyle(
            fontSize: currentFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          );

          final textPainter = TextPainter(
            text: TextSpan(text: widget.text, style: textStyle),
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

        final displayText = widget.text;

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
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              SizedBox(
                width:
                    currentFontSize * 0.6, // Fixed-width for the cursor space
                child: _cursorVisible
                    ? Text(
                        '|',
                        style: TextStyle(
                          fontSize: currentFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      )
                    : Container(), // Empty container when cursor is not visible
              ),
            ],
          ),
        );
      },
    );
  }
}
