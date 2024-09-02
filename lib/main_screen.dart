import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.history),
          onPressed: () {
            showHistoryDialog(context);
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 201, 189, 193),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _buildDisplayArea(),
          _buildButtonGrid(),
        ],
      ),
    );
  }

  Widget _buildDisplayArea() {
    return Container(
      height: 250,
      padding: EdgeInsets.all(15),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          // Show previous expression if available
          if (previousExpression.isNotEmpty)
            CalculatorDisplay(
              text: previousExpression + " =",
              maxFontSize: 30,
              textColor: Colors.black,
              isUserInput: false,
            ),
          // Show current input or result
          CalculatorDisplay(
            text: showingResult ? answer : userInput,
            maxFontSize: 60,
            textColor: Colors.black,
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
          color: Colors.white,
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
            return _buildButton(buttons[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildButton(String text, int index) {
    Color? color;
    Color? textColor;

    if (index == 0) {
      color = const Color.fromARGB(255, 201, 189, 193);
      textColor = Colors.black;
    } else if (index == 1 || index == 2 || index == 3) {
      color = const Color.fromARGB(248, 238, 234, 231);
      textColor = Colors.black;
    } else if (index == 18) {
      color = const Color.fromARGB(255, 201, 189, 193);
      textColor = Colors.white;
    } else {
      color = isOperator(text)
          ? const Color.fromARGB(248, 238, 234, 231)
          : Colors.white;
      textColor = isOperator(text) ? Colors.white : Colors.black;
    }

    return MyButton(
      buttontapped: () => onButtonClick(
        text,
      ),
      buttonText: text,
      color: color,
      textColor: textColor,
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
          history.add(CalculationHistory(
            title: "Calculation",
            equation: userInput,
            result: answer,
          ));
        }
      } else if (value == "DEL") {
        // Delete the last character from user input
        if (userInput.isNotEmpty) {
          userInput = userInput.substring(0, userInput.length - 1);
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
                );
              },
            ),
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

        do {
          final textStyle = TextStyle(
            fontSize: currentFontSize,
            fontWeight: FontWeight.bold,
            color: widget.textColor,
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
                        color: widget.textColor),
                    maxLines: 1,
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              if (widget.isUserInput) // Show cursor only if it's user input
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

class MyButton extends StatelessWidget {
  final Color? color;
  final Color? textColor;
  final String buttonText;
  final Function buttontapped;

  const MyButton({
    Key? key,
    this.color,
    this.textColor,
    required this.buttonText,
    required this.buttontapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        buttontapped();
      },
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: color,
            child: Center(
              child: Text(
                buttonText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
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
}
