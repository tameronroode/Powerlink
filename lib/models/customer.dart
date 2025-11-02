// lib/models/customer.dart
class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get name =>
      [firstName, lastName].where((s) => s.trim().isNotEmpty).join(' ').trim();

  /// Preferred constructor used everywhere
  factory Customer.fromJson(Map<String, dynamic> json) =>
      Customer._fromAny(json);

  /// Back-compat: some parts of app call fromRow
  factory Customer.fromRow(Map<String, dynamic> row) => Customer._fromAny(row);

  /// Unified parser that tolerates different casings/keys.
  factory Customer._fromAny(Map<String, dynamic> map) {
    String pickString(List<String> keys, {String fallback = ''}) {
      for (final k in keys) {
        final v = map[k];
        if (v != null) return v.toString();
      }
      return fallback;
    }

    // id may be bigint/int/string and key may vary
    dynamic rawId =
        map['id'] ??
        map['Id'] ??
        map['ID'] ??
        map['customer_id'] ??
        map['CustomerId'] ??
        map['CustomerID'];
    final id = rawId == null ? '' : rawId.toString();

    final first = pickString(['FirstName', 'first_name', 'firstName']);
    final last = pickString(['LastName', 'last_name', 'lastName']);
    final mail = pickString(['Email', 'email']);

    return Customer(id: id, firstName: first, lastName: last, email: mail);
  }


  Map<String, dynamic> toJson() => <String, dynamic>{
    'Id': id, // keep if your table stores/returns Id; safe to include as string
    'FirstName': firstName,
    'LastName': lastName,
    'Email': email.toLowerCase(),
  };

  Customer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }
}
