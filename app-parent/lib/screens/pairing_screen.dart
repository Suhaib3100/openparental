import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../state/providers.dart';

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
    final claimed = _status == 'CLAIMED';
    return Scaffold(
      appBar: AppBar(title: const Text('Pair a device')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: claimed
                ? [
                    const Icon(Icons.check_circle, color: Colors.green, size: 72),
                    const SizedBox(height: 16),
                    const Text('Device paired!', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ]
                : [
                    const Text('On the child device, open monii and enter this code:'),
                    const SizedBox(height: 24),
                    SelectableText(
                      widget.pairing.code,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('QR token (for scan):',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    SelectableText(
                      widget.pairing.qrToken,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 32),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Waiting for the device…'),
                      ],
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
