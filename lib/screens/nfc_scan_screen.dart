import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/gistag_pressable.dart';

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
    final resolution = await ref
        .read(workoutControllerProvider.notifier)
        .scanNfcTag();
    if (!mounted || resolution == null) {
      return;
    }
    context.go('/tag-success');
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Row(
                children: [
                  Text('태그 스캔', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  GistagPressable(
                    onTap: () => context.go('/home'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GistagColors.border),
                      ),
                      child: const Icon(Icons.close_rounded, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  children: [
                    const Spacer(),
                    _NfcScanVisual(isError: workoutState.hasError),
                    const SizedBox(height: 30),
                    Text(
                      workoutState.hasError ? '태그 확인 실패' : 'NFC 태그를 확인하고 있어요',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'MVP에서는 데모 태그로 장소 검증 API를 호출합니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GistagColors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    _DemoTagCard(
                      loading: workoutState.isLoading || workoutState.hasValue,
                    ),
                    const SizedBox(height: 24),
                    workoutState.when(
                      loading: () => const _ScanStatus(text: '장소를 확인하는 중'),
                      error: (error, _) => _ScanError(
                        message: '태그를 인식하지 못했어요. 다시 시도해주세요.',
                        onRetry: _scan,
                      ),
                      data: (_) => const _ScanStatus(text: '서버 응답을 기다리는 중'),
                    ),
                    const Spacer(),
                    GistagButton(
                      label: '스캔 취소',
                      onPressed: () => context.go('/home'),
                      backgroundColor: Colors.white,
                      foregroundColor: GistagColors.text,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NfcScanVisual extends StatelessWidget {
  const _NfcScanVisual({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? GistagColors.primaryDark : GistagColors.primary;

    return SizedBox(
      width: 196,
      height: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: 0.10),
                width: 18,
              ),
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: GistagColors.border),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(Icons.nfc_rounded, color: accent, size: 72),
          ),
        ],
      ),
    );
  }
}

class _DemoTagCard extends StatelessWidget {
  const _DemoTagCard({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: GistagColors.primarySoft.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: GistagColors.primaryDark,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GISTAG_TAG_DEMO_001',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  loading ? 'POST /tags/resolve' : '데모 태그 코드',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanStatus extends StatelessWidget {
  const _ScanStatus({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: GistagColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: GistagColors.primary,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GistagColors.primarySoft.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GistagColors.primarySoft),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: const Text('다시 태그하기')),
        ],
      ),
    );
  }
}
