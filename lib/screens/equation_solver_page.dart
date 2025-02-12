import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class EquationSolverPage extends StatefulWidget {
  const EquationSolverPage({Key? key}) : super(key: key);

  @override
  State<EquationSolverPage> createState() => _EquationSolverPageState();
}

class _EquationSolverPageState extends State<EquationSolverPage> {
  File? _image;
  final picker = ImagePicker();
  final textRecognizer = TextRecognizer();
  String recognizedText = '';
  String solution = '';
  bool isProcessing = false;

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          isProcessing = true;
          recognizedText = '';
          solution = '';
        });

        await processImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> processImage() async {
    if (_image == null) return;

    try {
      final inputImage = InputImage.fromFile(_image!);
      final recognizedText = await textRecognizer.processImage(inputImage);

      setState(() {
        this.recognizedText = recognizedText.text;
        isProcessing = false;
      });

      solveEquation(recognizedText.text);
    } catch (e) {
      setState(() {
        recognizedText = 'Error recognizing text: ${e.toString()}';
        isProcessing = false;
      });
    }
  }

  void solveEquation(String equation) {
    try {
      // Remove any unnecessary text and whitespace
      equation = equation.replaceAll(RegExp(r'[^0-9x+\-=/*().\s]'), '').trim();

      // Split equation into left and right sides
      List<String> sides = equation.split('=');
      if (sides.length != 2) {
        throw Exception('Invalid equation format');
      }

      String leftSide = sides[0].trim();
      String rightSide = sides[1].trim();

      // Parse coefficients
      double coefficient = 0;
      double constant = 0;
      double rightConstant = double.parse(rightSide);

      // Handle left side parsing
      RegExp termPattern = RegExp(r'([+-]?\s*\d*x)|([+-]?\s*\d+)');
      var matches = termPattern.allMatches(leftSide);

      for (var match in matches) {
        String? term = match.group(0)?.trim();
        if (term == null) continue;

        if (term.contains('x')) {
          // Handle coefficient of x
          String coeffStr = term.replaceAll('x', '');
          coeffStr =
              coeffStr.isEmpty ? '1' : (coeffStr == '-' ? '-1' : coeffStr);
          coefficient += double.parse(coeffStr);
        } else {
          // Handle constant
          constant += double.parse(term);
        }
      }

      // Solve for x: ax + b = c
      // ax = c - b
      // x = (c - b) / a
      double x = (rightConstant - constant) / coefficient;

      setState(() {
        solution = 'x = ${x.toStringAsFixed(2)}';
      });
    } catch (e) {
      setState(() {
        solution =
            'Could not solve equation. Please ensure it\'s in the format ax + b = c';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equation Solver'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_image != null)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _image!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _getImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[100],
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _getImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[100],
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isProcessing)
                const Center(child: CircularProgressIndicator()),
              if (recognizedText.isNotEmpty)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recognized Equation:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(recognizedText),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (solution.isNotEmpty)
                Card(
                  elevation: 2,
                  color: Colors.green[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solution:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          solution,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }
}
