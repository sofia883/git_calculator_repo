class CalculationHistory {
  final String equation;
  final String result;
  final String datetime; // New field for date and time

  CalculationHistory({
    required this.equation,
    required this.result,
    required this.datetime,
  });

  // Convert a CalculationHistory object into a Map object
  Map<String, dynamic> toJson() {
    return {
      'equation': equation,
      'result': result,
      'datetime': datetime,
    };
  }

  // Convert a Map object into a CalculationHistory object
  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    return CalculationHistory(
      equation: json['equation'],
      result: json['result'],
      datetime: json['datetime'] ??
          '', // Provide default value for backward compatibility
    );
  }
}
