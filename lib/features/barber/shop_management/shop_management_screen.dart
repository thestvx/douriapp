import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class ShopManagementScreen extends StatelessWidget {
  const ShopManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shopManagement)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              TextField(decoration: const InputDecoration(labelText: 'Shop name')),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(decoration: const InputDecoration(labelText: 'Appointment duration (min)')),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, child: Text(l10n.confirm))),
            ],
          ),
        ),
      ),
    );
  }
}
