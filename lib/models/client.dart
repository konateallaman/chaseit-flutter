class Client {
  final String id;
  String biz;
  String name;
  String email;
  String phone;
  String notes;

  Client({
    required this.id,
    required this.biz,
    this.name = '',
    required this.email,
    this.phone = '',
    this.notes = '',
  });

  String get displayName => biz.isNotEmpty ? biz : name;

  String get initials {
    final words = displayName.split(' ');
    return words.take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'biz': biz,
    'name': name,
    'email': email,
    'phone': phone,
    'notes': notes,
  };

  factory Client.fromMap(Map<String, dynamic> m) => Client(
    id: m['id'],
    biz: m['biz'] ?? '',
    name: m['name'] ?? '',
    email: m['email'],
    phone: m['phone'] ?? '',
    notes: m['notes'] ?? '',
  );
}
