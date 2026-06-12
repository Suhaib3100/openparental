import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
        child: SingleChildScrollView(
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
        const SizedBox(height: 4),
        Text('Scan to pair', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          "Open OpenParental on your child's phone and scan this code.",
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 28),
        // QR card
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: scheme.outline),
            ),
            child: QrImageView(
              data: widget.pairing.qrToken,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: Text('or enter the code',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.22)),
          ),
          alignment: Alignment.center,
          child: SelectableText(
            widget.pairing.code,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
              color: scheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 28),
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
      ],
    );
  }

  Widget _claimed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
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
      ),
    );
  }
}
