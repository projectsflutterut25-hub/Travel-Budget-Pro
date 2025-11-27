class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String role; // "admin" | "client"

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      role: data['role'] ?? 'client',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'displayName': displayName, 'role': role};
  }
}
