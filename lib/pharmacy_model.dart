class Pharmacy {
  final String name;
  final String address;
  final String phone;
  final String scheduleDescription;

  Pharmacy({
    required this.name,
    required this.address,
    required this.phone,
    required this.scheduleDescription,
  });
  // Add toJson and fromJson methods
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'scheduleDescription': scheduleDescription,
    };
  }

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    return Pharmacy(
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      scheduleDescription: json['scheduleDescription'],
    );
  }
}
