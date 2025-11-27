class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicleType;
  final String plate;
  final double baseSalary;
  final bool available;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.plate,
    required this.baseSalary,
    required this.available,
  });

  factory Driver.fromMap(String id, Map<String, dynamic> data) {
    return Driver(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      plate: data['plate'] ?? '',
      baseSalary: (data['baseSalary'] ?? 0).toDouble(),
      available: data['available'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'vehicleType': vehicleType,
      'plate': plate,
      'baseSalary': baseSalary,
      'available': available,
    };
  }
}
