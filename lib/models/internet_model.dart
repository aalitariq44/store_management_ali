class InternetSubscription {
  final int? id;
  final int personId;
  final String packageName;
  final double price;
  final double paidAmount;
  final int durationInDays;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  InternetSubscription({
    this.id,
    required this.personId,
    required this.packageName,
    required this.price,
    required this.paidAmount,
    required this.durationInDays,
    required this.startDate,
    required this.endDate,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(days: 3)).isAfter(endDate);
  double get remainingAmount => price - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_id': personId,
      'package_name': packageName,
      'price': price,
      'paid_amount': paidAmount,
      'duration_in_days': durationInDays,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
      'payment_date': paymentDate.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory InternetSubscription.fromMap(Map<String, dynamic> map) {
    return InternetSubscription(
      id: map['id'],
      personId: map['person_id'],
      packageName: map['package_name'],
      price: map['price'].toDouble(),
      paidAmount: map['paid_amount']?.toDouble() ?? 0.0,
      durationInDays: map['duration_in_days'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date']),
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['payment_date']),
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isActive: map['is_active'] == 1,
    );
  }

  InternetSubscription copyWith({
    int? id,
    int? personId,
    String? packageName,
    double? price,
    double? paidAmount,
    int? durationInDays,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? paymentDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return InternetSubscription(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      packageName: packageName ?? this.packageName,
      price: price ?? this.price,
      paidAmount: paidAmount ?? this.paidAmount,
      durationInDays: durationInDays ?? this.durationInDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'InternetSubscription(id: $id, personId: $personId, packageName: $packageName, price: $price, paidAmount: $paidAmount, durationInDays: $durationInDays, startDate: $startDate, endDate: $endDate, paymentDate: $paymentDate, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive)';
  }
}
