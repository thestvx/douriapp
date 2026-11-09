import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/supabase_service.dart';

class NotificationService {
  const NotificationService();

  Future<void> initialize(String userId) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      await SupabaseService.client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': 'android',
      });
    }
    messaging.onTokenRefresh.listen((newToken) async {
      await SupabaseService.client.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': newToken,
        'platform': 'android',
      });
    });
  }
}

final notificationServiceProvider = Provider((ref) => const NotificationService());
