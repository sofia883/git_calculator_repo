import 'package:calculator_app/common_imports.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add this line
  String liveResult = ''; // Add this variable for live calculation
  var userInput = '';
  var answer = '';
  List<CalculationHistory> history = [];
  bool showingResult = false;
  bool replaceInputWithResult = false;
  String previousExpression = '';
  bool isDarkMode = true;
  bool continueFromResult =
      false; // Add this variable to track post-equals state

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void updateLiveResult() {
    if (userInput.isNotEmpty) {
      String unformattedInput = userInput.replaceAll(',', '');
      // Always calculate live result, even when last char is operator
      if (isLastCharOperator()) {
        // Remove the last operator for calculation
        String inputForCalc =
            unformattedInput.substring(0, unformattedInput.length - 1);
        if (inputForCalc.isNotEmpty) {
          liveResult = formatNumber(calculateResult(inputForCalc));
        }
      } else {
        liveResult = formatNumber(calculateResult(unformattedInput));
      }
    } else {
      liveResult = '';
    }
  }

  // Update formatExpression to handle operators better
  String formatExpression(String input) {
    if (input.isEmpty) return input;

    // Split by operators while keeping the operators
    List<String> parts = input.split(RegExp(r'([+\-x/%])'));
    List<String> operators =
        input.split(RegExp(r'[0-9.,]+')).where((op) => op.isNotEmpty).toList();

    // Format each number in the expression
    String formatted = '';
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        // Remove existing commas before formatting
        String unformatted = parts[i].replaceAll(',', '');
        formatted += formatNumber(unformatted);
      }
      if (i < operators.length) {
        formatted += operators[i];
      }
    }

    return formatted;
  }

  String calculateResult(String input) {
    input = input.replaceAll(',', '').replaceAll('x', '*');
    try {
      Parser p = Parser();
      Expression exp = p.parse(input);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Format the result with 1 decimal place
      String result = eval.toStringAsFixed(1);
      // Remove trailing zero after decimal point if it exists
      if (result.endsWith('.0')) {
        result = result.substring(0, result.length - 2);
      }

      return result;
    } catch (e) {
      return "Error";
    }
  }

  // Update formatNumber to handle 4+ digits
  String formatNumber(String number) {
    if (number.isEmpty || number == "Error") return number;

    try {
      // Split into integer and decimal parts.
      List<String> parts = number.split('.');
      String integerPart = parts[0];
      bool isNegative = false;

      // Remove a leading '-' if present.
      if (integerPart.startsWith('-')) {
        isNegative = true;
        integerPart = integerPart.substring(1);
      }

      // If there are 3 or fewer digits, no formatting is needed.
      if (integerPart.length <= 3) {
        String unformatted = (isNegative ? '-' : '') + integerPart;
        if (parts.length > 1) {
          unformatted += '.' + parts[1];
        }
        return unformatted;
      }

      // Compute the size of the first group.
      // For example, for "9345" (length 4) the remainder is 1 so the first group is 1 digit.
      int remainder = integerPart.length % 3;
      String formattedInteger = '';

      // If there is a leading group (with remainder > 0), take that first.
      if (remainder > 0) {
        formattedInteger = integerPart.substring(0, remainder);
      }

      // Process the remaining digits in groups of 3.
      for (int i = remainder; i < integerPart.length; i += 3) {
        // If we already have some digits, append a comma.
        if (formattedInteger.isNotEmpty) {
          formattedInteger += ',';
        }
        formattedInteger += integerPart.substring(i, i + 3);
      }

      // Prepend a negative sign if needed.
      String result = (isNegative ? '-' : '') + formattedInteger;

      // Add the decimal part back, if it exists.
      if (parts.length > 1) {
        result += '.' + parts[1];
      }
      return result;
    } catch (e) {
      return number;
    }
  }

  void onButtonClick(String value) {
    setState(() {
      if (value == "AC") {
        userInput = '';
        answer = '';
        liveResult = '';
        previousExpression = '';
        showingResult = false;
        continueFromResult = false;
      } else if (value == "=") {
        if (userInput.isNotEmpty && !isLastCharOperator()) {
          String unformattedInput = userInput.replaceAll(',', '');
          answer = calculateResult(unformattedInput);
          if (answer != "Error") {
            answer = formatNumber(answer);
            final now = DateTime.now();
            history.add(CalculationHistory(
              datetime: now.toIso8601String(),
              equation: formatExpression(userInput),
              result: answer,
            ));
            _saveHistory();
          }
          previousExpression = formatExpression(userInput);
          userInput = '';
          showingResult = true;
          liveResult = '';
          continueFromResult = true;
        }
      } else if (value == "DEL") {
        if (showingResult) {
          userInput = answer.replaceAll(',', '');
          if (userInput.isNotEmpty) {
            userInput = userInput.substring(0, userInput.length - 1);
          }
          if (userInput.isEmpty) {
            showingResult = false;
            answer = '';
            previousExpression = '';
            continueFromResult = false;
          } else {
            answer = formatNumber(userInput);
          }
        } else {
          if (userInput.isNotEmpty) {
            String unformatted = userInput.replaceAll(',', '');
            userInput = unformatted.substring(0, unformatted.length - 1);
            updateLiveResult();
          }
        }
      } else {
        // Handle regular input
        if (showingResult) {
          if (isOperator(value)) {
            userInput = answer.replaceAll(',', '') + value;
            answer = '';
            showingResult = false;
            continueFromResult = false;
            previousExpression =
                ''; // Clear previous expression when starting new calculation
          } else {
            if (continueFromResult) {
              userInput = answer.replaceAll(',', '') + value;
            } else {
              userInput = value;
            }
            answer = '';
            showingResult = false;
            previousExpression = ''; // Clear previous expression
          }
        } else {
          if (isOperator(value)) {
            if (!isLastCharOperator() && userInput.isNotEmpty) {
              userInput += value;
            }
          } else if (value == ".") {
            // Handle decimal point
            if (userInput.isEmpty || isLastCharOperator()) {
              userInput += "0."; // Add leading zero
            } else {
              // Check if current number already has a decimal
              String currentNumber = userInput.split(RegExp(r'[+\-x/%]')).last;
              if (!currentNumber.contains('.')) {
                userInput += value;
              }
            }
          } else {
            String unformatted = userInput.replaceAll(',', '') + value;
            userInput = unformatted;
          }
        }

        updateLiveResult();
      }

      // Format the userInput numbers
      if (!showingResult && userInput.isNotEmpty) {
        userInput = formatExpression(userInput);
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
    'AC',
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
        width: MediaQuery.of(context).size.width * 0.65, // 65% of screen width
        child: showHistoryDrawer(context),
      ),
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default drawer icon
        forceMaterialTransparency: true,
        toolbarHeight: 80,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.list,
                color: isDarkMode ? Colors.white : Colors.black), // File icon
            onSelected: (String value) {
              if (value == 'theme') {
                _toggleTheme();
              } else if (value == 'history') {
                _scaffoldKey.currentState?.openDrawer(); // Open history drawer
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      isDarkMode ? Icons.sunny : Icons.dark_mode,
                      color: isDarkMode ? Colors.orange : Colors.black,
                    ),
                    SizedBox(width: 10),
                    Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('History'),
                  ],
                ),
              ),
            ],
          ),
        ],
        backgroundColor: Colors.transparent, // Transparent AppBar
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
        color: AppColors.getDrawerBackgroundColor(),
        child: Column(
          children: [
            // Drawer Header
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.getDrawerBackgroundColor(),
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
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.getDrawerBackgroundColor().withOpacity(0),
                            AppColors.getDrawerBackgroundColor()
                                .withOpacity(0.4),
                            AppColors.getDrawerBackgroundColor()
                                .withOpacity(0.7),
                            AppColors.getDrawerBackgroundColor(),
                          ],
                          stops: [0.0, 0.3, 0.6, 1.0],
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
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor:
                              const Color.fromARGB(255, 28, 27, 27),
                          title: Text(
                            'Delete All History?',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'This action cannot be undone.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                setState(() {
                                  history.clear();
                                });
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Close drawer
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'All history deleted successfully'),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Icon(
                    Icons.delete,
                    color: AppColors.getDrawerDeleteIconColor(),
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
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
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _handleHistoryTap(historyItem);
                    },
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor:
                                const Color.fromARGB(255, 28, 27, 27),
                            title: Text(
                              'Delete History Item?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              'This action cannot be undone.',
                              style: TextStyle(color: Colors.grey),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    history.removeAt(index);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('History item deleted'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
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
                    ),
                  ),
                );
              },
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
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 10),
          CalculatorDisplay(
            text: showingResult ? answer : userInput,
            maxFontSize: 60,
            textColor: AppColors.getDisplayTextColor(isDarkMode),
            isUserInput: true,
          ),
          if (!showingResult && liveResult.isNotEmpty)
            Text(
              '= ' + liveResult,
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey,
              ),
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
