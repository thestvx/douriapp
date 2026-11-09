import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../customer/home/shop_providers.dart';

class BarberDetailsScreen extends ConsumerWidget {
  const BarberDetailsScreen({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shops = ref.watch(shopsProvider);
    return Scaffold(
      body: shops.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) {
          final shop = list.firstWhere((s) => s.id == shopId, orElse: () => list.isNotEmpty ? list.first : list.first);
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    color: const Color(0xFF1B1B1B),
                    child: Center(child: Text(shop.shopName, style: Theme.of(context).textTheme.headlineMedium)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop.shopName, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(shop.address ?? '', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Text(shop.description ?? '', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/booking/${shop.id}'),
                            child: Text(l10n.bookNow),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
