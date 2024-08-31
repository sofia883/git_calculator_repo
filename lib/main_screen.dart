import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;

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
  String _result = "";
  bool _showAdditionalOperations = false;
  bool _isRadMode = false;

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

  void _toggleExtraButton() {
    setState(() {
      _showAdditionalOperations = !_showAdditionalOperations;
    });
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _output = "";
        _equation = "";
        _result = "";
        _fontSize = 60.0;
      } else if (buttonText == "=") {
        if (_result.isNotEmpty) {
          _output = _result;
          _result = "";
        } else {
          _equation = _output;
          try {
            var result = _evaluateExpression(_output);
            _result = result.toStringAsFixed(2);
            if (_result != "Error") {
              _showSaveSnackBar();
            }
          } catch (e) {
            _result = "Error";
          }
        }
      } else if (buttonText == "⌫") {
        if (_output.isNotEmpty) {
          _output = _output.substring(0, _output.length - 1);
        }
      } else if (["sin", "cos", "tan", "log", "ln", "√", "inv"]
          .contains(buttonText)) {
        _output += "$buttonText(";
      } else if (buttonText == "rad" || buttonText == "deg") {
        _isRadMode = buttonText == "rad";
      } else {
        _output += buttonText;
        _result = "";
      }
      _updateFontSize();
    });
  }

  double _evaluateExpression(String expression) {
    expression = expression.replaceAll('x', '*');
    expression = expression.replaceAll('÷', '/');
    expression = expression.replaceAll('π', math.pi.toString());
    expression = expression.replaceAll('e', math.e.toString());

    // Handle trigonometric and logarithmic functions
    expression = _handleMathFunctions(expression);

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

  String _handleMathFunctions(String expression) {
    expression = expression.replaceAllMapped(RegExp(r'sin\((.*?)\)'),
        (match) => math.sin(double.parse(match.group(1)!)).toString());
    expression = expression.replaceAllMapped(RegExp(r'cos\((.*?)\)'),
        (match) => math.cos(double.parse(match.group(1)!)).toString());
    expression = expression.replaceAllMapped(RegExp(r'tan\((.*?)\)'),
        (match) => math.tan(double.parse(match.group(1)!)).toString());
    expression = expression.replaceAllMapped(RegExp(r'log\((.*?)\)'),
        (match) => math.log(double.parse(match.group(1)!)).toString());
    return expression;
  }

  void _showSaveSnackBar() {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Enter title",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _currentTitle = value,
            ),
          ),
          TextButton(
            child: Text("Save"),
            onPressed: () {
              _addToHistory();
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ],
      ),
      duration: Duration(days: 365), // Long duration to keep it open
      behavior: SnackBarBehavior.floating, // Make the SnackBar float
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
        left: 10,
        right: 10,
      ), // Adjust margin to appear above keyboard
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Calculation History"),
          content: Container(
            width: double.maxFinite,
            child: _history.isEmpty
                ? Center(child: Text("No history available"))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text("${item.equation} = ${item.result}"),
                        onTap: () {
                          setState(() {
                            _output = item.equation;
                            _result = item.result;
                          });
                          Navigator.of(context).pop();
                        },
                        visualDensity: VisualDensity(
                            vertical: -4), // Reduce vertical padding
                      );
                    },
                  ),
          ),
          actions: [
            if (_history.isNotEmpty)
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

  void _addToHistory() {
    if (_currentTitle.isNotEmpty) {
      setState(() {
        _history.insert(
          0,
          CalculationHistory(
            title: _currentTitle,
            equation: _equation,
            result: _result,
          ),
        );
        _currentTitle = "";
      });
      _saveHistory();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back),
        actions: [
          IconButton(
            icon: Icon(Icons.calculate),
            onPressed: _toggleExtraButton, // Toggle extra button visibility
          ),
          Icon(Icons.grid_4x4),
          Icon(Icons.more_vert),
        ],
        backgroundColor: Color(0xFFFAF0E6),
        elevation: 0,
      ),
      body: _buildCalculatorUI(context),
    );
  }

  Widget _buildCalculatorUI(BuildContext context) {
    Color bgColor = Color(0xFFFAF0E6);
    Color textColor = Colors.black;
    Color buttonColor = Colors.white;
    Color orangeColor = Color(0xFFFFA000);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CalculatorDisplay(text: _output, textColor: textColor),
                if (_result.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "= $_result",
                        style: TextStyle(fontSize: 24, color: textColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              children: [
                _buildButtonGrid(buttonColor, textColor, orangeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid(
      Color buttonColor, Color textColor, Color orangeColor) {
    List<List<String>> buttonLayout = [
      ['sin', 'cos', 'tan', 'rad', _isRadMode ? 'deg' : 'rad'],
      ['log', 'ln', '(', ')', 'inv'],
      ['!', 'AC', '%', '⌫', '÷'],
      ['^', '7', '8', '9', '×'],
      ['√', '4', '5', '6', '-'],
      ['π', '1', '2', '3', '+'],
      ['e', '00', '0', '.', '='],
    ];

    return Column(
      children: buttonLayout.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((button) {
            Color currentColor = button == 'AC'
                ? orangeColor
                : button == '='
                    ? orangeColor
                    : buttonColor;
            Color currentTextColor =
                (button == 'AC' || button == '=') ? Colors.white : textColor;
            return _buildButton(button, currentColor, currentTextColor);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildButtonRow(
      List<String> buttons, Color buttonColor, Color textColor,
      [Color? specialColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons.map((button) {
          Color currentButtonColor = button == 'AC' || button == '='
              ? specialColor ?? Colors.orange
              : buttonColor;
          Color currentTextColor =
              (button == 'AC' || button == '=') ? Colors.white : textColor;
          return _buildButton(button, currentButtonColor, currentTextColor);
        }).toList(),
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
            SizedBox(height: 5), // Reduced space between buttons
          ],
        );
      }).toList(),
    );
  }

  Widget _buildButton(String text, Color buttonColor, Color textColor) {
    return Container(
      width: 70,
      height: 70,
      margin: EdgeInsets.all(2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        onPressed: () => _onButtonPressed(text),
      ),
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
  final Color textColor;

  const CalculatorDisplay({
    Key? key,
    required this.text,
    this.maxFontSize = 60,
    required this.textColor,
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
    Color textColor =
        _CalculatorState()._isDarkMode ? Colors.white : Colors.black;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth - 40;
        double currentFontSize = widget.maxFontSize;
        double textWidth = double.infinity; // Initialize textWidth

        do {
          final textStyle = TextStyle(
            fontSize: currentFontSize,
            fontWeight: FontWeight.bold,
            color: _CalculatorState()._isDarkMode ? Colors.white : Colors.black,
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

          if (currentFontSize < 15) {
            currentFontSize = 15;
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
                        color: widget.textColor),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
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
