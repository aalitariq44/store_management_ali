class Debt {
  final int? id;
  final String? title;
  final int personId;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPaid;
  final DateTime? paymentDate;

  Debt({
    this.id,
    this.title,
    required this.personId,
    required this.amount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isPaid = false,
    this.paymentDate,
  });

  double get remainingAmount => isPaid ? 0.0 : amount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'person_id': personId,
      'amount': amount,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_paid': isPaid ? 1 : 0,
      'payment_date': paymentDate?.millisecondsSinceEpoch,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      title: map['title'],
      personId: map['person_id'],
      amount: map['amount'].toDouble(),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isPaid: map['is_paid'] == 1,
      paymentDate: map['payment_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['payment_date'])
          : null,
    );
  }

  Debt copyWith({
    int? id,
    String? title,
    int? personId,
    double? amount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPaid,
    DateTime? paymentDate,
  }) {
    return Debt(
      id: id ?? this.id,
      title: title ?? this.title,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPaid: isPaid ?? this.isPaid,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  @override
  String toString() {
    return 'Debt(id: $id, title: $title, personId: $personId, amount: $amount, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, isPaid: $isPaid, paymentDate: $paymentDate)';
  }
}
