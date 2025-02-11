import 'package:calculator_app/common_imports.dart';

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