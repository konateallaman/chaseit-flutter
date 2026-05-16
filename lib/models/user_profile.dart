class UserProfile {
  String id;
  String businessName;
  String ownerName;
  String email;
  String phone;
  String plan;
  String createdAt;
  String avatarUrl;
  bool emailVerified;

  UserProfile({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.email,
    this.phone = '',
    this.plan = 'free',
    required this.createdAt,
    this.avatarUrl = '',
    this.emailVerified = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'businessName': businessName,
    'ownerName': ownerName,
    'email': email,
    'phone': phone,
    'plan': plan,
    'createdAt': createdAt,
    'avatarUrl': avatarUrl,
    'emailVerified': emailVerified,
  };

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    id: m['id'] ?? '',
    businessName: m['businessName'] ?? '',
    ownerName: m['ownerName'] ?? '',
    email: m['email'] ?? '',
    phone: m['phone'] ?? '',
    plan: m['plan'] ?? 'free',
    createdAt: m['createdAt'] ?? DateTime.now().toIso8601String(),
    avatarUrl: m['avatarUrl'] ?? '',
    emailVerified: m['emailVerified'] ?? false,
  );

  UserProfile copyWith({
    String? businessName, String? ownerName, String? email,
    String? phone, String? plan, String? avatarUrl, bool? emailVerified,
  }) => UserProfile(
    id: id,
    businessName: businessName ?? this.businessName,
    ownerName: ownerName ?? this.ownerName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    plan: plan ?? this.plan,
    createdAt: createdAt,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    emailVerified: emailVerified ?? this.emailVerified,
  );
}
