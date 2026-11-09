class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.barberShopId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingDate,
    required this.bookingTime,
    this.queueNumber,
    required this.status,
    this.rejectionReason,
  });

  final String id;
  final String customerId;
  final String barberShopId;
  final String customerName;
  final String customerPhone;
  final DateTime bookingDate;
  final String bookingTime;
  final int? queueNumber;
  final String status;
  final String? rejectionReason;

  factory Booking.fromMap(Map<String, dynamic> map) => Booking(
        id: map['id'] as String,
        customerId: map['customer_id'] as String,
        barberShopId: map['barber_shop_id'] as String,
        customerName: (map['customer_name'] ?? '') as String,
        customerPhone: (map['customer_phone'] ?? '') as String,
        bookingDate: DateTime.parse(map['booking_date'] as String),
        bookingTime: (map['booking_time'] ?? '') as String,
        queueNumber: map['queue_number'] as int?,
        status: (map['status'] ?? 'PENDING') as String,
        rejectionReason: map['rejection_reason'] as String?,
      );
}
