import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class QueueTicketScreen extends StatelessWidget {
  const QueueTicketScreen({super.key, required this.queueNumber});
  final int queueNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.queueNumber, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(queueNumber.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(color: const Color(0xFFC8F078))),
                const SizedBox(height: 24),
                Text(l10n.customersAhead, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('0', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                Text(l10n.estimatedWait, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
