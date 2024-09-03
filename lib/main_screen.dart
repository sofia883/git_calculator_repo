import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var userInput = '';
  var answer = '';
  List<CalculationHistory> history = [];
  bool showingResult = false;
  bool replaceInputWithResult = false;
  String previousExpression = '';
  bool isDarkMode = true;
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  final List<String> buttons = [
    'C',
    '-/+',
    '%',
    'DEL',
    '7',
    '8',
    '9',
    '/',
    '4',
    '5',
    '6',
    'x',
    '1',
    '2',
    '3',
    '-',
    '0',
    '.',
    '=',
    '+',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        forceMaterialTransparency: true,
        toolbarHeight: 80,
        leading: IconButton(
          color: isDarkMode ? Colors.white : Colors.black,
          icon: Icon(Icons.history),
          onPressed: () {
            showHistoryDialog(context);
          },
        ),
        actions: [
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 60, // Adjust width as needed
                height: 30, // Adjust height as needed
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 7),
                    ),
                  ],
                  color: isDarkMode ? Colors.black : Colors.white,
                  border: Border.all(
                    color: isDarkMode ? Colors.black : Colors.white,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: isDarkMode ? _toggleTheme : null,
                      child: AnimatedOpacity(
                        opacity: isDarkMode ? 1.0 : 0.2,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.sunny,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: isDarkMode ? null : _toggleTheme,
                      child: AnimatedOpacity(
                        opacity: isDarkMode ? 0.2 : 1.0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.dark_mode,
                          color: const Color.fromARGB(255, 46, 54, 58),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
        ],
        backgroundColor:
            Colors.transparent, // Makes the AppBar background transparent
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildDisplayArea(),
          _buildButtonGrid(),
        ],
      ),
    );
  }

  Widget _buildDisplayArea() {
    return Container(
      height: 230.0,
      padding: EdgeInsets.only(bottom: 30, right: 8, left: 8),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          // Show previous expression if available
          if (previousExpression.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    previousExpression,
                    style: TextStyle(
                      fontSize: 30,
                      color: AppColors.getDisplayTextColor(isDarkMode),
                    ),
                  ),
                  Text(
                    ' = ',
                    style: TextStyle(
                      fontSize: 30,
                      color:
                          Colors.orange, // This will make the "=" sign orange
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 10,
          ),
          // Show current input or result
          CalculatorDisplay(
            text: showingResult ? answer : userInput,
            maxFontSize: 60,
            textColor: AppColors.getDisplayTextColor(isDarkMode),
            isUserInput: true,
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Expanded(
      flex: 5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getButtonColor(isDarkMode),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(40),
            topLeft: Radius.circular(40),
          ),
        ),
        child: GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 10),
          itemCount: buttons.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
          ),
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildButton(buttons[index], index),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton(String text, int index) {
    Color? color;
    Color? textColor;
    double borderRadius = index < 4 ? 20.0 : 45.0;

    if (index == 0) {
      color = AppColors.getButtonColor(isDarkMode);
      textColor = isDarkMode
          ? const Color.fromARGB(243, 175, 250, 1)
          : const Color.fromARGB(255, 18, 200, 24);
    } else if (index == 1 || index == 2) {
      color = AppColors.getButtonColor(isDarkMode);

      textColor = AppColors.getButtonTextColor(isDarkMode);
    } else if (index == 3) {
      textColor = Colors.red;
    } else if (index == 18) {
      color = Colors.orange;
      textColor = AppColors.getButtonTextColor(isDarkMode);
    } else {
      color = isOperator(text)
          ? AppColors.getButtonColor(isDarkMode)
          : Colors.white;
      textColor = isDarkMode
          ? isOperator(text)
              ? AppColors.getButtonTextColor(isDarkMode)
              : Colors.white
          : Colors.black;
    }
    return MyButton(
      buttontapped: () => onButtonClick(text),
      buttonText: text,
      textColor: textColor,
      color: index == 18 ? Colors.orange : AppColors.getButtonColor(isDarkMode),
      borderRadius: borderRadius,
    );
  }

  bool isOperator(String x) {
    return x == '/' || x == 'x' || x == '-' || x == '+' || x == '=';
  }

  void onButtonClick(String value) {
    setState(() {
      if (value == "C") {
        // Clear everything
        userInput = '';
        answer = '';
        previousExpression = '';
        showingResult = false;
      } else if (value == "=") {
        if (userInput.isNotEmpty) {
          // Calculate the result
          answer = calculateResult(userInput);
          if (answer == "Error") {
            // If there's an error, show the error message
            showingResult = true;
          }
          // Set previousExpression to current input
          previousExpression = userInput;
          // Display the result and clear user input for new calculations
          userInput = '';
          showingResult = true;
          if (answer != "Error") {
            history.add(CalculationHistory(
              title: "Calculation",
              equation: previousExpression,
              result: answer,
            ));
            _saveHistory(); // Save history to SharedPreferences
          }
        }
      } else if (value == "DEL") {
        if (showingResult) {
          // If result is shown, start a new input from scratch
          if (userInput.isNotEmpty) {
            userInput = userInput.substring(0, userInput.length - 1);
          }
          if (userInput.isEmpty) {
            // If input becomes empty after deletion, reset showingResult
            showingResult = false;
            answer = '';
          }
        } else {
          // Normal delete behavior
          if (userInput.isNotEmpty) {
            userInput = userInput.substring(0, userInput.length - 1);
          }
        }
      } else {
        if (showingResult) {
          // If result is shown and user starts new input, clear result but not the input
          if (answer == "Error") {
            // If error was shown, start fresh input
            userInput = value;
            answer = ''; // Clear previous error
            showingResult = false;
          } else {
            // If result was shown correctly, use the result as a base
            userInput =
                answer + value; // Append new input to the previous result
            answer = ''; // Clear previous result
            showingResult = false;
          }
        } else {
          // Append the button value to the input
          userInput += value;
        }
      }
    });
  }

// Dummy calculateResult method

  String calculateResult(String input) {
    input = input.replaceAll('x', '*');
    try {
      Parser p = Parser();
      Expression exp = p.parse(input);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Format the result to remove trailing zeros
      String result = eval.toString();
      if (result.contains('.')) {
        result = result.replaceAll(RegExp(r'([.]*?)0+$'), '');
        if (result.endsWith('.')) {
          result = result.substring(0, result.length - 1);
        }
      }

      return result;
    } catch (e) {
      return "Error";
    }
  }

  void _evaluateExpression() {
    String finalUserInput = userInput.replaceAll('x', '*');
    Parser p = Parser();
    Expression exp = p.parse(finalUserInput);
    ContextModel cm = ContextModel();
    double eval = exp.evaluate(EvaluationType.REAL, cm);
    setState(() {
      answer = eval.toString();
      history.add(CalculationHistory(
        title: "Calculation",
        equation: userInput,
        result: answer,
      ));
    });
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  void showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("History"),
          content: _buildHistoryList(),
          actions: _buildHistoryActions(context),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return Container(
      width: double.maxFinite,
      child: history.isEmpty
          ? Text(
              'No History Added Yet',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(history[index].title),
                  subtitle: Text(
                      "${history[index].equation} = ${history[index].result}"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleHistoryTap(history[index]);
                  },
                );
              },
            ),
    );
  }

  void _handleHistoryTap(CalculationHistory item) {
    setState(() {
      userInput = item.equation;
      answer = item.result;
      showingResult = true;
      previousExpression = item.equation;
    });
  }

  void _handleDeleteCharacter() {
    setState(() {
      if (userInput.isNotEmpty) {
        userInput = userInput.substring(0, userInput.length - 1);
      }
    });
  }

  void _saveHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> encodedHistory =
        history.map((historyItem) => jsonEncode(historyItem.toJson())).toList();
    prefs.setStringList('calculationHistory', encodedHistory);
  }

  void _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? encodedHistory = prefs.getStringList('calculationHistory');
    if (encodedHistory != null) {
      setState(() {
        history = encodedHistory
            .map((historyItem) =>
                CalculationHistory.fromJson(jsonDecode(historyItem)))
            .toList();
      });
    }
  }

  Widget _buildDelButton() {
    return ElevatedButton(
      onPressed: _handleDeleteCharacter,
      child: Text("DEL"),
    );
  }

  List<Widget> _buildHistoryActions(BuildContext context) {
    return [
      if (history.isNotEmpty)
        TextButton(
          child: Text("Clear All"),
          onPressed: () {
            setState(() {
              history.clear();
            });
            Navigator.of(context).pop();
            showHistoryDialog(context);
          },
        ),
      TextButton(
        child: Text("Close"),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ];
  }
}

class MyButton extends StatelessWidget {
  final VoidCallback buttontapped;
  final String buttonText;
  final Color color;
  final Color textColor;
  final double borderRadius;

  MyButton({
    required this.buttontapped,
    required this.buttonText,
    required this.color,
    required this.textColor,
    this.borderRadius = 45.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: buttontapped,
      child: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class AppColors {
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? const Color.fromARGB(201, 28, 28, 28) : Colors.white;
  }

  static Color getButtonColor(bool isDarkMode) {
    return isDarkMode ? const Color.fromARGB(255, 10, 10, 10)! : Colors.white;
  }

  static Color getButtonTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black;
  }

  static Color getDisplayTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black;
  }
}

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

class CalculationHistory {
  final String title;
  final String equation;
  final String result;

  CalculationHistory({
    required this.title,
    required this.equation,
    required this.result,
  });

  // Convert a CalculationHistory object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'equation': equation,
      'result': result,
    };
  }

  // Convert a Map object into a CalculationHistory object
  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    return CalculationHistory(
      title: json['title'],
      equation: json['equation'],
      result: json['result'],
    );
  }
}
