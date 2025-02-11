import 'package:calculator_app/common_imports.dart';

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

 static Color getDrawerBackgroundColor() {
    return const Color.fromARGB(255, 28, 27, 27);
  }



  static Color getDrawerDeleteIconColor() {
    return const Color.fromARGB(255, 239, 16, 0);
  }
}
