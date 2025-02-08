import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';


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