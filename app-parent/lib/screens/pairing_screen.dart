import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';

class PairingScreen extends ConsumerStatefulWidget {
  final Pairing pairing;
  const PairingScreen({super.key, required this.pairing});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  Timer? _timer;
  String _status = 'PENDING';

  @override
  void initState() {
    super.initState();
    _status = widget.pairing.status;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final status = await ref.read(apiProvider).pairingStatus(widget.pairing.id);
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'CLAIMED' || status == 'EXPIRED') _timer?.cancel();
    } catch (_) {
      // keep polling
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final claimed = _status == 'CLAIMED';

    return Scaffold(
      appBar: AppBar(title: const Text('Pair a device')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: claimed ? _claimed(context) : _pending(context, scheme),
        ),
      ),
    );
  }

  Widget _pending(BuildContext context, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Enter this code',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          "Open OpenParental on your child's phone and type the code below.",
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
          ),
          alignment: Alignment.center,
          child: SelectableText(
            widget.pairing.code,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Text('QR token',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              SelectableText(
                widget.pairing.qrToken,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Waiting for the device…',
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _claimed(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.online, size: 76),
        const SizedBox(height: 18),
        Text('Device paired',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text("You're all set.",
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15)),
        const SizedBox(height: 32),
        SizedBox(
          width: 200,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
