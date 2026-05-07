import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';

class NfcScanScreen extends ConsumerStatefulWidget {
  const NfcScanScreen({super.key});

  @override
  ConsumerState<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends ConsumerState<NfcScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    final place = await ref
        .read(workoutControllerProvider.notifier)
        .scanNfcTag();
    if (!mounted || place == null) {
      return;
    }
    context.go('/tag-success');
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              const Spacer(),
              Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.nfc_rounded,
                  color: GistagColors.primary,
                  size: 82,
                ),
              ),
              const SizedBox(height: 34),
              Text(
                'NFC 태그를 인식하는 중',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '휴대폰을 리더기에 가까이 태그해주세요',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: GistagColors.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              workoutState.when(
                loading: () => const CircularProgressIndicator(
                  color: GistagColors.primary,
                ),
                error: (error, _) => _ScanError(
                  message: '태그를 인식하지 못했어요. 다시 시도해주세요.',
                  onRetry: _scan,
                ),
                data: (_) => const CircularProgressIndicator(
                  color: GistagColors.primary,
                ),
              ),
              const Spacer(),
              GistagButton(
                label: '취소',
                onPressed: () => context.go('/home'),
                backgroundColor: Colors.white,
                foregroundColor: GistagColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanError extends StatelessWidget {
  const _ScanError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          style: const TextStyle(color: GistagColors.primary),
          textAlign: TextAlign.center,
        ),
        TextButton(onPressed: onRetry, child: const Text('다시 태그하기')),
      ],
    );
  }
}
