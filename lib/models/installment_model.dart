class Installment {
  final int? id;
  final int personId;
  final String productName;
  final double totalAmount;
  final double paidAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCompleted;

  Installment({
    this.id,
    required this.personId,
    required this.productName,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isCompleted = false,
  });

  double get remainingAmount => totalAmount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_id': personId,
      'product_name': productName,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory Installment.fromMap(Map<String, dynamic> map) {
    return Installment(
      id: map['id'],
      personId: map['person_id'],
      productName: map['product_name'],
      totalAmount: map['total_amount'].toDouble(),
      paidAmount: map['paid_amount'].toDouble(),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isCompleted: map['is_completed'] == 1,
    );
  }

  Installment copyWith({
    int? id,
    int? personId,
    String? productName,
    double? totalAmount,
    double? paidAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return Installment(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      productName: productName ?? this.productName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'Installment(id: $id, personId: $personId, productName: $productName, totalAmount: $totalAmount, paidAmount: $paidAmount, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, isCompleted: $isCompleted)';
  }
}

class InstallmentPayment {
  final int? id;
  final int installmentId;
  final double amount;
  final String? notes;
  final DateTime paymentDate;
  final DateTime createdAt;

  InstallmentPayment({
    this.id,
    required this.installmentId,
    required this.amount,
    this.notes,
    required this.paymentDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'installment_id': installmentId,
      'amount': amount,
      'notes': notes,
      'payment_date': paymentDate.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory InstallmentPayment.fromMap(Map<String, dynamic> map) {
    return InstallmentPayment(
      id: map['id'],
      installmentId: map['installment_id'],
      amount: map['amount'].toDouble(),
      notes: map['notes'],
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['payment_date']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  InstallmentPayment copyWith({
    int? id,
    int? installmentId,
    double? amount,
    String? notes,
    DateTime? paymentDate,
    DateTime? createdAt,
  }) {
    return InstallmentPayment(
      id: id ?? this.id,
      installmentId: installmentId ?? this.installmentId,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'InstallmentPayment(id: $id, installmentId: $installmentId, amount: $amount, notes: $notes, paymentDate: $paymentDate, createdAt: $createdAt)';
  }
}
