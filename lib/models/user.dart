class User {
  final int? id;
  final String username;
  final String password;

  User({
    this.id,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
    );
  }

  User copyWith({int? id, String? username, String? password}) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  @override
  String toString() => 'User(id: $id, username: $username)';
}
