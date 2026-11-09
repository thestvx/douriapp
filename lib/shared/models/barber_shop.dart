class BarberShop {
  const BarberShop({
    required this.id,
    required this.ownerId,
    required this.shopName,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.logoUrl,
    this.coverImageUrl,
    this.appointmentDuration = 30,
    this.maximumDailyBookings = 30,
    this.isOpen = false,
  });

  final String id;
  final String ownerId;
  final String shopName;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? logoUrl;
  final String? coverImageUrl;
  final int appointmentDuration;
  final int maximumDailyBookings;
  final bool isOpen;

  factory BarberShop.fromMap(Map<String, dynamic> map) => BarberShop(
        id: map['id'] as String,
        ownerId: map['owner_id'] as String,
        shopName: (map['shop_name'] ?? '') as String,
        description: map['description'] as String?,
        address: map['address'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        phoneNumber: map['phone_number'] as String?,
        logoUrl: map['logo_url'] as String?,
        coverImageUrl: map['cover_image_url'] as String?,
        appointmentDuration: (map['appointment_duration'] ?? 30) as int,
        maximumDailyBookings: (map['maximum_daily_bookings'] ?? 30) as int,
        isOpen: (map['is_open'] ?? false) as bool,
      );
}
