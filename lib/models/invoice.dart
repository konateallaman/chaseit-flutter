class Invoice {
  final String id;
  String client;
  String email;
  double amount;
  double paidAmount;
  String due;
  String desc;
  String sender;
  String num;
  String seq;
  String phone;
  int chases;
  bool paid;
  String created;

  Invoice({
    required this.id,
    required this.client,
    required this.email,
    required this.amount,
    this.paidAmount = 0,
    required this.due,
    this.desc = '',
    this.sender = '',
    required this.num,
    this.seq = 'gentle',
    this.phone = '',
    this.chases = 0,
    this.paid = false,
    required this.created,
  });

  double get remaining => (amount - paidAmount).clamp(0, double.infinity);
  bool get isFullyPaid => paid || paidAmount >= amount;

  String get status {
    if (isFullyPaid) return 'paid';
    if (paidAmount > 0) return 'partial';
    final days = daysOverdue;
    return days > 0 ? 'overdue' : 'pending';
  }

  int get daysOverdue {
    final due_ = DateTime.tryParse(due);
    if (due_ == null) return 0;
    return DateTime.now().difference(due_).inDays;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'client': client, 'email': email,
    'amount': amount, 'paidAmount': paidAmount, 'due': due,
    'desc': desc, 'sender': sender, 'num': num, 'seq': seq,
    'phone': phone, 'chases': chases, 'paid': paid ? 1 : 0, 'created': created,
  };

  factory Invoice.fromMap(Map<String, dynamic> m) => Invoice(
    id: m['id'] as String, client: m['client'] as String, email: m['email'] as String,
    amount: _toDouble(m['amount']), paidAmount: _toDouble(m['paidAmount']),
    due: m['due'] as String, desc: (m['desc'] ?? '') as String,
    sender: (m['sender'] ?? '') as String, num: (m['num'] ?? '') as String,
    seq: (m['seq'] ?? 'gentle') as String, phone: (m['phone'] ?? '') as String,
    chases: (m['chases'] ?? 0) as int, paid: ((m['paid'] ?? 0) as int) == 1,
    created: m['created'] as String,
  );

  Invoice copyWith({
    String? client, String? email, double? amount, double? paidAmount,
    String? due, String? desc, String? sender, String? num,
    String? seq, String? phone, int? chases, bool? paid,
  }) => Invoice(
    id: id, client: client ?? this.client, email: email ?? this.email,
    amount: amount ?? this.amount, paidAmount: paidAmount ?? this.paidAmount,
    due: due ?? this.due, desc: desc ?? this.desc, sender: sender ?? this.sender,
    num: num ?? this.num, seq: seq ?? this.seq, phone: phone ?? this.phone,
    chases: chases ?? this.chases, paid: paid ?? this.paid, created: created,
  );
}
