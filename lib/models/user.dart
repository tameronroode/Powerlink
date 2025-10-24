class AppUser {
  final String userId;
  final String email;
  final String userType; // 'customer' or 'employee'
  final String? role; // //employee role

  AppUser({
    required this.userId,
    required this.email,
    required this.userType,
    this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'userType': userType,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['user_id'] ?? map['userId'],
      email: map['email'],
      userType: map['user_type'] ?? map['userType'],
      role: map['role'],
    );
  }
}