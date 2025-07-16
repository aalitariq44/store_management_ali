class Income {
  final int? id;
  final double amount;
  final String description;
  final DateTime date;

  Income({
    this.id,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      description: map['description'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }
}
