import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/repository_providers.dart';
import '../../shared/models/profile.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  bool _saving = false;

  Future<void> _choose(String role) async {
    setState(() => _saving = true);
    final profile = Profile(id: widget.uid, fullName: '', appRole: role);
    await ref.read(profileRepositoryProvider).upsertProfile(profile);
    if (role == 'barber') {
      await ref.read(barberShopRepositoryProvider).upsertShop({
        'owner_id': widget.uid,
        'shop_name': 'My Barber Shop',
      });
    }
    if (!mounted) return;
    context.go(role == 'barber' ? '/barber' : '/customer');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.getStarted, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _choose('customer'),
                  child: const Text('I am a customer'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _choose('barber'),
                  child: const Text('I am a barber'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
