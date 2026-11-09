/// A service offered by a barbershop. Maps to the existing
/// `shop_services` table (see supabase/migrations/001_init.sql).
class ShopService {
  const ShopService({
    required this.id,
    required this.barberShopId,
    required this.serviceName,
    this.description,
    this.durationMinutes = 30,
    this.price,
    this.isActive = true,
  });

  final String id;
  final String barberShopId;
  final String serviceName;
  final String? description;
  final int durationMinutes;
  final double? price;
  final bool isActive;

  factory ShopService.fromMap(Map<String, dynamic> map) => ShopService(
        id: map['id'] as String,
        barberShopId: map['barber_shop_id'] as String,
        serviceName: (map['service_name'] ?? '') as String,
        description: map['description'] as String?,
        durationMinutes: (map['duration_minutes'] ?? 30) as int,
        price: (map['price'] as num?)?.toDouble(),
        isActive: (map['is_active'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'barber_shop_id': barberShopId,
        'service_name': serviceName,
        'description': description,
        'duration_minutes': durationMinutes,
        'price': price,
        'is_active': isActive,
      };
}
