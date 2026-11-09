import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../booking_requests/booking_requests_screen.dart';
import '../queue_management/queue_management_screen.dart';
import '../shop_management/shop_management_screen.dart';
import 'shop_provider.dart';

class BarberDashboardScreen extends ConsumerStatefulWidget {
  const BarberDashboardScreen({super.key});
  @override
  ConsumerState<BarberDashboardScreen> createState() => _BarberDashboardScreenState();
}

class _BarberDashboardScreenState extends ConsumerState<BarberDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shop = ref.watch(currentShopProvider);
    final shopId = shop.value?.id;
    final pages = <Widget>[
      _DashboardBody(shop: shop.value),
      shopId == null ? const _Placeholder('No shop') : BookingRequestsScreen(shopId: shopId),
      shopId == null ? const _Placeholder('No shop') : QueueManagementScreen(shopId: shopId),
      const ShopManagementScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking List', style: const TextStyle(color: AppColors.primaryAccent, fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBackground,
        actions: [
          TextButton(onPressed: () {}, child: const Text('Logout', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12))),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(25),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Date : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ),
        ),
      ),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: AppColors.primaryBackground,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: Colors.white54,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard), label: l10n.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.inbox), label: l10n.bookingRequests),
          BottomNavigationBarItem(icon: const Icon(Icons.queue), label: l10n.queueManagement),
          BottomNavigationBarItem(icon: const Icon(Icons.store), label: l10n.shopManagement),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({this.shop});
  final dynamic shop;
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(shop?.shopName ?? 'Dashboard', style: const TextStyle(color: Colors.white, fontSize: 24)));
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Center(child: Text(label, style: const TextStyle(color: Colors.white)));
}
