class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final String? profileImage;
  final String userType;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.profileImage,
    required this.userType,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      profileImage: json['profile_image'],
      userType: json['user_type'] ?? 'farmer',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_image': profileImage,
      'user_type': userType,
      'created_at': createdAt,
    };
  }
}
