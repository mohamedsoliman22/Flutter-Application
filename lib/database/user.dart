class User {
  final int? id;
  final String email;
  final String password;
  final String name;
  final bool isAdmin;
  final String? cardNumber;
  final String? cardName;
  final String? cardExpiry;
  final String? cardCVV;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.name,
    this.isAdmin = false,
    this.cardNumber,
    this.cardName,
    this.cardExpiry,
    this.cardCVV,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'is_admin': isAdmin ? 1 : 0,
      'card_number': cardNumber,
      'card_name': cardName,
      'card_expiry': cardExpiry,
      'card_cvv': cardCVV,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      email: map['email'] as String,
      password: map['password'] as String,
      name: map['name'] as String,
      isAdmin: map['is_admin'] == 1,
      cardNumber: map['card_number'] as String?,
      cardName: map['card_name'] as String?,
      cardExpiry: map['card_expiry'] as String?,
      cardCVV: map['card_cvv'] as String?,
    );
  }
} 