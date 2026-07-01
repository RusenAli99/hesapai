class UserModel {
  final String uid;
  final String name;
  final String email;
  final String currencyCode;
  final String currencySymbol;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.currencyCode = 'TRY',
    this.currencySymbol = '₺',
  });

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? currencyCode,
    String? currencySymbol,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'currencyCode': currencyCode,
      'currencySymbol': currencySymbol,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      currencyCode: map['currencyCode'] ?? 'TRY',
      currencySymbol: map['currencySymbol'] ?? '₺',
    );
  }
}
