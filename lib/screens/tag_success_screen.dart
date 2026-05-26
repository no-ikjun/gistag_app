import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../models/gistag_models.dart';
import '../providers/app_providers.dart';
import '../widgets/common/gistag_button.dart';
import '../widgets/common/gistag_header.dart';

class TagSuccessScreen extends ConsumerStatefulWidget {
  const TagSuccessScreen({super.key});

  @override
  ConsumerState<TagSuccessScreen> createState() => _TagSuccessScreenState();
}

class _TagSuccessScreenState extends ConsumerState<TagSuccessScreen> {
  Future<void> _startWorkout() async {
    final resolution = ref.read(workoutControllerProvider).value?.resolvedTag;
    if (resolution == null) {
      context.go('/scan');
      return;
    }

    await ref.read(workoutControllerProvider.notifier).startWorkout(resolution);
    if (!mounted) {
      return;
    }
    if (!ref.read(workoutControllerProvider).hasError) {
      context.go('/workout');
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutControllerProvider);
    final resolution = workoutState.value?.resolvedTag;
    final place = resolution?.place;
    final starting = workoutState.isLoading;

    if (place == null && !starting) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
            child: Column(
              children: [
                GistagHeader(
                  centerTitle: true,
                  showBellAction: false,
                  center: Text(
                    '장소 확인',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.nfc_rounded,
                  color: GistagColors.primary,
                  size: 52,
                ),
                const SizedBox(height: 16),
                Text(
                  '확인된 NFC 태그가 없어요',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '다시 태그를 스캔해 장소를 확인해주세요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                GistagButton(
                  label: '다시 태그하기',
                  onPressed: () => context.go('/scan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          children: [
            GistagHeader(
              centerTitle: true,
              showBellAction: false,
              center: Text(
                '장소 확인',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 22),
            _VerifiedBanner(resolution: resolution),
            const SizedBox(height: 18),
            _PlaceConfirmationCard(place: place),
            const SizedBox(height: 14),
            _TagDetailsCard(resolution: resolution),
            if (resolution?.canStartWorkout == false) ...[
              const SizedBox(height: 14),
              _BlockedMessage(
                message: resolution?.blockedReason ?? '이 태그로는 운동을 시작할 수 없어요.',
              ),
            ],
            if (workoutState.hasError) ...[
              const SizedBox(height: 14),
              const _BlockedMessage(message: '운동을 시작하지 못했어요. 다시 시도해주세요.'),
            ],
            const SizedBox(height: 28),
            GistagButton(
              label: starting ? '운동 시작 중' : '운동 시작',
              onPressed: starting || resolution?.canStartWorkout != true
                  ? null
                  : _startWorkout,
            ),
            const SizedBox(height: 10),
            GistagButton(
              label: '다시 태그하기',
              onPressed: starting ? null : () => context.go('/scan'),
              backgroundColor: Colors.white,
              foregroundColor: GistagColors.text,
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedBanner extends StatelessWidget {
  const _VerifiedBanner({required this.resolution});

  final NfcTagResolution? resolution;

  @override
  Widget build(BuildContext context) {
    final blocked = resolution?.canStartWorkout == false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: blocked
            ? GistagColors.primarySoft.withValues(alpha: 0.22)
            : const Color(0xFFEFFAF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: blocked
              ? GistagColors.primarySoft
              : GistagColors.success.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              blocked
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: blocked ? GistagColors.primaryDark : GistagColors.success,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blocked ? '태그는 확인됐지만 시작할 수 없어요' : '등록된 운동 장소입니다',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  blocked ? '상태를 확인한 뒤 다시 시도해주세요.' : '장소 정보를 한 번 더 확인해 주세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
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

class _PlaceConfirmationCard extends StatelessWidget {
  const _PlaceConfirmationCard({required this.place});

  final Place? place;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: GistagColors.primarySoft.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: GistagColors.primaryDark,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place?.name ?? '운동 장소',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 21,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place?.workoutType ?? '운동',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GistagColors.primaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((place?.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              place!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5F6368),
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TagDetailsCard extends StatelessWidget {
  const _TagDetailsCard({required this.resolution});

  final NfcTagResolution? resolution;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GistagColors.border),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.confirmation_number_outlined,
            label: '태그 코드',
            value: resolution?.tag.code ?? '-',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.verified_outlined,
            label: '태그 상태',
            value: resolution?.tag.status ?? '-',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: GistagColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: GistagColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: GistagColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _BlockedMessage extends StatelessWidget {
  const _BlockedMessage({required this.message});

  final String message;

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
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: GistagColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
