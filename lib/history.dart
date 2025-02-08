
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
