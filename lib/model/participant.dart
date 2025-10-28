class Participant {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String password;

  Participant({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'password': password,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      city: map['city'],
      password: map['password'],
    );
  }
}
