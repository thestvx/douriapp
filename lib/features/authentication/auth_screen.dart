import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/repository_providers.dart';
import 'auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final repo = ref.read(authRepositoryProvider);
    await repo.sendOtp(
      phoneNumber: '+213${_phoneController.text.trim()}',
      onCodeSent: (id) {
        setState(() {
          _verificationId = id;
          _sending = false;
        });
      },
      onFailed: (e) {
        setState(() {
          _error = e.message;
          _sending = false;
        });
      },
    );
  }

  Future<void> _verify() async {
    if (_verificationId == null) return;
    setState(() => _sending = true);
    try {
      final cred = await ref.read(authRepositoryProvider).verifyOtp(
            verificationId: _verificationId!,
            smsCode: _otpController.text.trim(),
          );
      final uid = cred.user!.uid;
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getProfile(uid);
      try {
        await ref.read(notificationServiceProvider).initialize(uid);
      } catch (_) {}
      if (!mounted) return;
      if (profile == null) {
        context.go('/role/$uid');
      } else if (profile.appRole == 'barber') {
        context.go('/barber');
      } else {
        context.go('/customer');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Text('Admin Panel', style: TextStyle(color: AppColors.primaryAccent, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 10),
              const Icon(Icons.content_cut, size: 100, color: AppColors.primaryAccent),
              const SizedBox(height: 20),
              const Text("Let's Login", style: TextStyle(color: AppColors.primaryAccent, fontSize: 40, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Column(
                  children: [
                    const Text('Phone Login', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('🇩🇿 +213', style: TextStyle(color: AppColors.primaryBackground)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_verificationId != null)
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: 'OTP',
                          border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.white)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryBackground),
                        onPressed: _sending ? null : (_verificationId == null ? _sendOtp : _verify),
                        child: Text(_sending ? l10n.loading : (_verificationId == null ? l10n.verify : l10n.confirm)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                        onPressed: () => context.go('/customer'),
                        child: const Text('دخول كعميل (تجربة)'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                        onPressed: () => context.go('/barber'),
                        child: const Text('دخول كحلاق (تجربة)'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
