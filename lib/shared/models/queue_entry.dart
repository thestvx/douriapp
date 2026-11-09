/// One customer's place in a daily queue. Maps to the existing
/// `queue_entries` table. Statuses are exactly the DB check constraint:
/// WAITING, APPROACHING, CURRENT, COMPLETED, SKIPPED, CANCELLED.
class QueueEntry {
  const QueueEntry({
    required this.id,
    required this.dailyQueueId,
    required this.bookingId,
    required this.customerId,
    required this.queueNumber,
    required this.status,
    this.customerName,
    this.bookingTime,
  });

  final String id;
  final String dailyQueueId;
  final String bookingId;
  final String customerId;
  final int queueNumber;
  final String status;
  final String? customerName;
  final String? bookingTime;

  bool get isWaiting => status == 'WAITING';
  bool get isApproaching => status == 'APPROACHING';
  bool get isCurrent => status == 'CURRENT';
  bool get isCompleted => status == 'COMPLETED';
  bool get isSkipped => status == 'SKIPPED';
  bool get isCancelled => status == 'CANCELLED';

  factory QueueEntry.fromMap(Map<String, dynamic> map) {
    final booking = map['bookings'] as Map<String, dynamic>?;
    return QueueEntry(
      id: map['id'] as String,
      dailyQueueId: map['daily_queue_id'] as String,
      bookingId: map['booking_id'] as String,
      customerId: map['customer_id'] as String,
      queueNumber: (map['queue_number'] ?? 0) as int,
      status: (map['status'] ?? 'WAITING') as String,
      customerName: booking?['customer_name'] as String?,
      bookingTime: booking?['booking_time'] as String?,
    );
  }
}

/// Review row from the existing `reviews` table. Only used to compute a
/// real average rating — never invent one when there are no reviews.
class Review {
  const Review({required this.id, required this.rating, this.comment});
  final String id;
  final int rating;
  final String? comment;

  factory Review.fromMap(Map<String, dynamic> map) => Review(
        id: map['id'] as String,
        rating: (map['rating'] ?? 0) as int,
        comment: map['comment'] as String?,
      );
}
