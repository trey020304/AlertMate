class UserFields {
  static final String phone = 'phone';
  static final String password = 'password';

  static List<String> getFields() => [phone, password];
}

class User {
  final String phone;
  final String password;

  User({required this.phone, required this.password});

  // Convert from Map (Google Sheets data) to User object
  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      phone: data['phone'], // Assuming the column name is 'phone'
      password: data['password'], // Assuming the column name is 'password'
    );
  }
}
