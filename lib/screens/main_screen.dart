import 'package:calculator_app/themes/colors.dart';
import 'package:calculator_app/screens/display_screen.dart';
import 'package:calculator_app/history.dart';
import 'package:calculator_app/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add this line

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

  void onButtonClick(String value) {
    setState(() {
      if (value == "C") {
        // Clear everything
        userInput = '';
        answer = '';
        previousExpression = '';
        showingResult = false;
      } else if (value == "=") {
        if (userInput.isNotEmpty && !isLastCharOperator()) {
          // Calculate the result
          answer = calculateResult(userInput);
          if (answer == "Error") {
            showingResult = true;
          }
          previousExpression = userInput;
          userInput = '';
          showingResult = true;

          if (answer != "Error") {
            final now = DateTime.now();
            history.add(CalculationHistory(
              datetime: now.toIso8601String(),
              equation: previousExpression,
              result: answer,
            ));
            _saveHistory();
          }
        }
      } else if (value == "DEL") {
        if (showingResult) {
          // If showing result, convert answer to userInput for deletion
          userInput = answer;
          if (userInput.isNotEmpty) {
            userInput = userInput.substring(0, userInput.length - 1);
          }
          // If all digits are deleted, reset everything
          if (userInput.isEmpty) {
            showingResult = false;
            answer = '';
            previousExpression = '';
          } else {
            // Update answer to show modified number
            answer = userInput;
          }
        } else {
          // Normal delete behavior
          if (userInput.isNotEmpty) {
            userInput = userInput.substring(0, userInput.length - 1);
          }
        }
      } else if (value == "00") {
        if (showingResult) {
          // Append 00 to the current result
          answer = answer + "00";
        } else if (userInput.isNotEmpty || value == "0") {
          userInput += "00";
        }
      } else {
        // Handle operators and numbers
        if (isOperator(value) || value == '%') {
          // If trying to add an operator
          if (!isLastCharOperator()) {
            if (showingResult) {
              // If there's a result, use it as the starting point
              userInput = answer + value;
              answer = '';
              showingResult = false;
            } else if (userInput.isNotEmpty) {
              userInput += value;
            }
          }
        } else if (value == ".") {
          // Special handling for decimal point
          if (showingResult) {
            // If showing result, start new number with "0."
            userInput = "0.";
            answer = '';
            showingResult = false;
          } else {
            // Check if we need to add a leading zero
            if (userInput.isEmpty) {
              userInput = "0.";
            } else {
              // Find the last operator in the input
              int lastOperatorIndex = -1;
              for (int i = userInput.length - 1; i >= 0; i--) {
                if (isOperator(userInput[i]) || userInput[i] == '%') {
                  lastOperatorIndex = i;
                  break;
                }
              }

              // If decimal point comes right after operator or at start
              if (lastOperatorIndex == userInput.length - 1 ||
                  (lastOperatorIndex == -1 && userInput.isEmpty)) {
                userInput += "0.";
              } else {
                userInput += ".";
              }
            }
          }
        } else {
          // For numbers
          if (showingResult) {
            // Append the number to the current result
            answer = answer + value;
          } else {
            userInput += value;
          }
        }
      }
    });
  }

// Helper method to get the last operator index
  int getLastOperatorIndex() {
    for (int i = userInput.length - 1; i >= 0; i--) {
      if (isOperator(userInput[i]) || userInput[i] == '%') {
        return i;
      }
    }
    return -1;
  }

  bool isLastCharOperator() {
    if (userInput.isEmpty) return false;
    String lastChar = userInput[userInput.length - 1];
    return isOperator(lastChar) || lastChar == '%';
  }

  bool isOperator(String x) {
    return x == '/' || x == 'x' || x == '-' || x == '+' || x == '=';
  }

  final List<String> buttons = [
    'C',
    '00', // Changed from '-/+'
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
      drawer: SizedBox(
        // Add width constraint to drawer
        width: MediaQuery.of(context).size.width * 0.65, // 75% of screen width
        child: showHistoryDrawer(context),
      ),
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      key: _scaffoldKey, // Add this line
      appBar: AppBar(
        forceMaterialTransparency: true,
        toolbarHeight: 80,
        leading: IconButton(
          color: isDarkMode ? Colors.white : Colors.black,
          icon: Icon(Icons.history),
          onPressed: () {
            _scaffoldKey.currentState
                ?.openDrawer(); // Use this instead of Scaffold.of(context)
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

  Drawer showHistoryDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color.fromARGB(255, 28, 27, 27),
        child: Column(
          children: [
            // Drawer Header
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 28, 27, 27),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 35.0),
                child: Center(
                  child: Text(
                    'History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            // History List with Enhanced Fade Effect
            Expanded(
              child: Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(bottom: 10),
                    child: _buildHistoryList(),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    height: 80, // Increased height for more blur
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromARGB(255, 28, 27, 27).withOpacity(0),
                            Color.fromARGB(255, 28, 27, 27).withOpacity(0.4),
                            Color.fromARGB(255, 28, 27, 27).withOpacity(0.7),
                            Color.fromARGB(255, 28, 27, 27),
                          ],
                          stops: [
                            0.0,
                            0.3,
                            0.6,
                            1.0
                          ], // Added more gradient stops for smoother transition
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Delete Icon Container
            if (history.isNotEmpty)
              Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20, bottom: 20),
                child: GestureDetector(
                  onTap: () {
                    _showDeleteConfirmation(context);
                  },
                  child: Icon(
                    Icons.delete,
                    color: const Color.fromARGB(255, 239, 16, 0),
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.black87, // Dark background
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Delete all history?",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                "All history will be permanently deleted from this device. This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        history.clear();
                        _saveHistory();
                      });
                      Navigator.of(context).pop();

                      // Show Snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'History cleared successfully',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.black87,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Text(
                      "Delete all",
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return Container(
      width: double.maxFinite,
      child: history.isEmpty
          ? Center(
              child: Text(
                'No History Added Yet',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: history.length,
              itemBuilder: (BuildContext context, int index) {
                final historyItem = history[index];
                final date = DateTime.parse(historyItem.datetime);

                // Format date and time in the requested format
                final months = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec'
                ];
                final day = date.day;
                final month = months[date.month - 1];
                final hour = date.hour > 12 ? date.hour - 12 : date.hour;
                final period = date.hour >= 12 ? 'pm' : 'am';
                final formattedDateTime =
                    '${day}th $month, ${hour}:${date.minute.toString().padLeft(2, '0')} $period';

                return Card(
                  elevation: 0,
                  color: const Color.fromARGB(255, 28, 27, 27),
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: historyItem.equation,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: ' = ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(
                                text: historyItem.result,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formattedDateTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Divider(
                          thickness: 0.5,
                        )
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleHistoryTap(historyItem);
                    },
                  ),
                );
              },
            ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
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
        padding: EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: AppColors.getButtonColor(isDarkMode),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(40),
            topLeft: Radius.circular(40),
          ),
        ),
        child: GridView.builder(
          padding: EdgeInsets.all(15),
          itemCount: buttons.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 3,
          ),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
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

  // void onButtonClick(String value) {
  //   setState(() {
  //     if (value == "C") {
  //       // Clear everything
  //       userInput = '';
  //       answer = '';
  //       previousExpression = '';
  //       showingResult = false;
  //     } else if (value == "=") {
  //       if (userInput.isNotEmpty) {
  //         // Calculate the result
  //         answer = calculateResult(userInput);
  //         if (answer == "Error") {
  //           // If there's an error, show the error message
  //           showingResult = true;
  //         }
  //         // Set previousExpression to current input
  //         previousExpression = userInput;
  //         // Display the result and clear user input for new calculations
  //         userInput = '';
  //         showingResult = true;
  //         if (answer != "Error") {
  //           history.add(CalculationHistory(
  //             title: "Calculation",
  //             equation: previousExpression,
  //             result: answer,
  //           ));
  //           _saveHistory(); // Save history to SharedPreferences
  //         }
  //       }
  //     } else if (value == "DEL") {
  //       if (showingResult) {
  //         // If result is shown, start a new input from scratch
  //         if (userInput.isNotEmpty) {
  //           userInput = userInput.substring(0, userInput.length - 1);
  //         }
  //         if (userInput.isEmpty) {
  //           // If input becomes empty after deletion, reset showingResult
  //           showingResult = false;
  //           answer = '';
  //         }
  //       } else {
  //         // Normal delete behavior
  //         if (userInput.isNotEmpty) {
  //           userInput = userInput.substring(0, userInput.length - 1);
  //         }
  //       }
  //     } else {
  //       if (showingResult) {
  //         // If result is shown and user starts new input, clear result but not the input
  //         if (answer == "Error") {
  //           // If error was shown, start fresh input
  //           userInput = value;
  //           answer = ''; // Clear previous error
  //           showingResult = false;
  //         } else {
  //           // If result was shown correctly, use the result as a base
  //           userInput =
  //               answer + value; // Append new input to the previous result
  //           answer = ''; // Clear previous result
  //           showingResult = false;
  //         }
  //       } else {
  //         // Append the button value to the input
  //         userInput += value;
  //       }
  //     }
  //   });
  // }

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

  void _handleHistoryTap(CalculationHistory item) {
    setState(() {
      userInput = item.equation;
      answer = item.result;
      showingResult = true;
      previousExpression = item.equation;
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
