import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../screens/detail_screen.dart';
import 'drag_to_dismiss_sheet.dart';
import 'media_image.dart';
import 'pressable_scale.dart';

/// CRAFT-ROULETTE-1: opens the constraint-based "Pick For Me" roulette as a
/// themed drag-to-dismiss sheet, the same convention every other focused
/// task in this app already uses (`LoungeRatingSheet`, `QuickStatusSheet`,
/// `HallSelectorSheet`, `LoungeFolderPickerSheet`, `LoungeRewatchSheet`) --
/// not a new full-screen route.
Future<void> showPickForMeRouletteSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.ambianceColors.scrim,
    builder: (sheetContext) => DragToDismissSheet(
      isDark: context.ambianceColors.isDark,
      onDismiss: () => Navigator.of(sheetContext).pop(),
      child: const PickForMeRouletteSheet(),
    ),
  );
}

/// Upgrades the simple "Pick For Me" randomizer into a filterable roulette:
/// Type/Runtime/Service/Mood constraint chips narrow the candidate pool
/// (still sourced from Watchlist + Saved, exactly like the existing
/// [PickForMeCard] -- SP-1: reusing the proven pool source, not inventing
/// a new one), a curtain-reveal animation (spring physics, per the
/// judgment call's own "spring reel / curtain reveal" framing) resolves
/// to the winning title, and the result offers Watch Now / Roll Again /
/// (conditionally) Add to Watchlist.
class PickForMeRouletteSheet extends ConsumerStatefulWidget {
  const PickForMeRouletteSheet({super.key});

  @override
  ConsumerState<PickForMeRouletteSheet> createState() =>
      _PickForMeRouletteSheetState();
}

class _PickForMeRouletteSheetState extends ConsumerState<PickForMeRouletteSheet>
    with SingleTickerProviderStateMixin {
  MediaType _type = MediaType.movie;
  int? _maxRuntime; // null = Any
  String? _service; // null = Any
  String? _genre; // null = Any
  MediaItem? _result;

  late final AnimationController _curtainController;
  late final Animation<double> _curtainAnim;

  @override
  void initState() {
    super.initState();
    _curtainController = AnimationController(
      vsync: this,
      duration: AppPhysics.houseSpringDuration,
    );
    _curtainAnim = CurvedAnimation(
        parent: _curtainController, curve: AppPhysics.houseSpringCurve);
  }

  @override
  void dispose() {
    _curtainController.dispose();
    super.dispose();
  }

  List<MediaItem> _pool(MediaState state) {
    final candidates = <String, MediaItem>{};
    for (final item in [...state.watchlist.values, ...state.maybeList.values]) {
      if (item.type != _type) continue;
      candidates.putIfAbsent(item.id, () => item);
    }

    return candidates.values.where((item) {
      if (_maxRuntime != null &&
          (item.runtime == null || item.runtime! > _maxRuntime!)) {
        return false;
      }
      if (_genre != null && !item.genres.contains(_genre)) return false;
      if (_service != null) {
        final providers = item
            .getWatchProvidersForCountry(state.watchProvidersCountry)
            .map((p) => p.providerName);
        if (!providers.contains(_service)) return false;
      }
      return true;
    }).toList();
  }

  void _resetResult() {
    if (_result != null) {
      setState(() => _result = null);
      _curtainController.value = 0;
    }
  }

  void _spin(List<MediaItem> pool) {
    if (pool.isEmpty) return;
    final random = Random();
    MediaItem picked;
    if (pool.length == 1) {
      picked = pool.first;
    } else {
      do {
        picked = pool[random.nextInt(pool.length)];
      } while (picked.id == _result?.id);
    }
    setState(() => _result = picked);
    _curtainController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final state = ref.watch(mediaProvider);
    final pool = _pool(state);

    // A filter change can invalidate the current result -- close the
    // curtain rather than leave a stale winner that no longer matches.
    if (_result != null && !pool.any((i) => i.id == _result!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resetResult());
    }

    final availableGenres = pool.expand((i) => i.genres).toSet().toList()
      ..sort();
    final availableServices = pool
        .expand((i) => i
            .getWatchProvidersForCountry(state.watchProvidersCountry)
            .map((p) => p.providerName))
        .toSet()
        .toList()
      ..sort();

    return Container(
      decoration: BoxDecoration(
        color: colors.base,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: colors.lineRgba, width: 1),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick For Me',
              style: AppThemes.display(
                context,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Narrow it down, then spin.',
              style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
            ),
            const SizedBox(height: 18),
            _FilterRow<MediaType>(
              label: 'Type',
              value: _type,
              options: const [
                (MediaType.movie, 'Movies'),
                (MediaType.tv, 'TV Shows'),
              ],
              onChanged: (v) {
                setState(() => _type = v);
                _resetResult();
              },
            ),
            const SizedBox(height: 12),
            _FilterRow<int?>(
              label: 'Runtime',
              value: _maxRuntime,
              options: const [
                (null, 'Any'),
                (90, 'Under 90m'),
                (120, 'Under 120m'),
              ],
              onChanged: (v) {
                setState(() => _maxRuntime = v);
                _resetResult();
              },
            ),
            if (availableServices.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FilterRow<String?>(
                label: 'Service',
                value: _service,
                options: [
                  (null, 'Any'),
                  for (final s in availableServices) (s, s),
                ],
                onChanged: (v) {
                  setState(() => _service = v);
                  _resetResult();
                },
              ),
            ],
            if (availableGenres.isNotEmpty) ...[
              const SizedBox(height: 12),
              _FilterRow<String?>(
                label: 'Mood',
                value: _genre,
                options: [
                  (null, 'Any'),
                  for (final g in availableGenres) (g, g),
                ],
                onChanged: (v) {
                  setState(() => _genre = v);
                  _resetResult();
                },
              ),
            ],
            const SizedBox(height: 22),
            _CurtainReveal(
              anim: _curtainAnim,
              result: _result,
              poolSize: pool.length,
            ),
            const SizedBox(height: 18),
            if (pool.isEmpty)
              Text(
                'No titles on your Watchlist or Saved match these filters yet.',
                textAlign: TextAlign.center,
                style: AppThemes.safeGeist(
                    fontSize: 13, color: colors.sub, height: 1.4),
              )
            else if (_result == null)
              PressableScale(
                onTap: () => _spin(pool),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: colors.primaryButtonDecoration
                      .copyWith(borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.casino_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Spin the Reel',
                        style: AppThemes.safeGeist(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _ResultActions(
                item: _result!,
                canAddToWatchlist: !state.watchlist.containsKey(_result!.id),
                onRollAgain: () => _spin(pool),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  const _FilterRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppThemes.safeGeist(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: colors.sub,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: PressableScale(
                    onTap: () => onChanged(option.$1),
                    child: AnimatedContainer(
                      duration: AppPhysics.houseSpringDuration,
                      curve: AppPhysics.houseSpringCurve,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: option.$1 == value ? colors.acc : colors.ph,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              option.$1 == value ? colors.acc : colors.lineRgba,
                        ),
                      ),
                      child: Text(
                        option.$2,
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight: option.$1 == value
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: option.$1 == value
                              ? Theme.of(context).colorScheme.onPrimary
                              : colors.sub,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurtainReveal extends StatelessWidget {
  final Animation<double> anim;
  final MediaItem? result;
  final int poolSize;

  const _CurtainReveal({
    required this.anim,
    required this.result,
    required this.poolSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: colors.card,
              alignment: Alignment.center,
              child: result != null
                  ? _RevealedCard(item: result!)
                  : Icon(
                      poolSize == 0
                          ? Icons.sentiment_dissatisfied_rounded
                          : Icons.casino_outlined,
                      size: 40,
                      color: colors.sub.withValues(alpha: 0.5),
                    ),
            ),
            AnimatedBuilder(
              animation: anim,
              builder: (context, child) {
                final t = anim.value;
                return Row(
                  children: [
                    Expanded(
                      child: FractionalTranslation(
                        translation: Offset(-t, 0),
                        child: Container(color: colors.card2),
                      ),
                    ),
                    Expanded(
                      child: FractionalTranslation(
                        translation: Offset(t, 0),
                        child: Container(color: colors.card2),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealedCard extends StatelessWidget {
  final MediaItem item;

  const _RevealedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 80,
            height: 120,
            child: MediaImage(
                item: item, fit: BoxFit.cover, showFallbackTitle: false),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppThemes.display(
                  context,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
              ),
              if (item.rating > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 13, color: colors.acc),
                    const SizedBox(width: 3),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.ink),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ResultActions extends ConsumerWidget {
  final MediaItem item;
  final bool canAddToWatchlist;
  final VoidCallback onRollAgain;

  const _ResultActions({
    required this.item,
    required this.canAddToWatchlist,
    required this.onRollAgain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PressableScale(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        DetailScreen(id: item.prefixedId, initialItem: item),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: colors.primaryButtonDecoration
                      .copyWith(borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.center,
                  child: Text(
                    'Watch Now',
                    style: AppThemes.safeGeist(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PressableScale(
                onTap: onRollAgain,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.acc
                        .withValues(alpha: colors.isDark ? 0.15 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: colors.acc.withValues(alpha: 0.4)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shuffle, size: 15, color: colors.acc),
                      const SizedBox(width: 6),
                      Text(
                        'Roll Again',
                        style: AppThemes.safeGeist(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: colors.acc,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (canAddToWatchlist) ...[
          const SizedBox(height: 10),
          PressableScale(
            onTap: () {
              ref.read(mediaProvider.notifier).addToWatchlist(item);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.lineRgba),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_add_outlined,
                      size: 15, color: colors.sub),
                  const SizedBox(width: 6),
                  Text(
                    'Add to Watchlist',
                    style: AppThemes.safeGeist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.sub,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
