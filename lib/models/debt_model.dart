class Debt {
  final int? id;
  final int personId;
  final double amount;
  final double paidAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPaid;

  Debt({
    this.id,
    required this.personId,
    required this.amount,
    this.paidAmount = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isPaid = false,
  });

  double get remainingAmount => amount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_id': personId,
      'amount': amount,
      'paid_amount': paidAmount,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_paid': isPaid ? 1 : 0,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      personId: map['person_id'],
      amount: map['amount'].toDouble(),
      paidAmount: map['paid_amount'].toDouble(),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isPaid: map['is_paid'] == 1,
    );
  }

  Debt copyWith({
    int? id,
    int? personId,
    double? amount,
    double? paidAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPaid,
  }) {
    return Debt(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  @override
  String toString() {
    return 'Debt(id: $id, personId: $personId, amount: $amount, paidAmount: $paidAmount, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, isPaid: $isPaid)';
  }
}
