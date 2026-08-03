import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';
import '../widgets/trailer_player.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailScreen extends ConsumerWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(mediaDetailsProvider(id));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: isDark
            ? AppThemes.screeningRoomBackground()
            : AppThemes.readingRoomBackground(),
        child: Scaffold(
          backgroundColor: isDark ? AppColors.srBase : AppColors.rrBase,
          appBar: AppBar(
            leading: PressableScale(
              onTap: () => Navigator.maybePop(context),
              child: Icon(Icons.arrow_back, color: inkColor),
            ),
            title: Text(
              'Details',
              style: GoogleFonts.bodoniModa(
                fontStyle: FontStyle.italic,
                color: inkColor,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: inkColor),
          ),
          body: detailAsync.when(
            data: (item) {
              if (item == null) {
                return const Center(child: Text('Failed to load details.'));
              }
              final isLarge = MediaQuery.of(context).size.width > 800;

              if (isLarge) {
                return _buildLargeLayout(context, ref, item, isDark);
              }
              return _buildCompactLayout(context, ref, item, isDark);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Failed to load details.')),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(context, item, isDark)
              .animate()
              .fade(duration: 250.ms),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: inkColor,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildMetaRow(item, isDark),
                    if (item.genres.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildGenreChips(item, isDark),
                    ],
                    const SizedBox(height: 18),
                    _buildActionButtons(ref, item, isDark),
                    const SizedBox(height: 22),
                    ExpandableOverviewText(
                      text: item.overview,
                      style: AppThemes.safeGeist(
                        fontSize: 14,
                        height: 1.5,
                        color: subColor,
                      ),
                      isDark: isDark,
                    ),
                  ],
                )
                    .animate(delay: 100.ms)
                    .fade(duration: 250.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      curve: AppPhysics.houseSpringCurve,
                    ),
                const SizedBox(height: 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCastStrip(item, isDark),
                    const SizedBox(height: 22),
                    _buildWatchProvidersSection(context, ref, item, isDark),
                  ],
                )
                    .animate(delay: 220.ms)
                    .fade(duration: 250.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      curve: AppPhysics.houseSpringCurve,
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeLayout(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: _buildHero(context, item, isDark)
                .animate()
                .fade(duration: 250.ms),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: inkColor,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildMetaRow(item, isDark),
                    if (item.genres.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildGenreChips(item, isDark),
                    ],
                    const SizedBox(height: 24),
                    _buildActionButtons(ref, item, isDark),
                    const SizedBox(height: 24),
                    ExpandableOverviewText(
                      text: item.overview,
                      style: AppThemes.safeGeist(
                        fontSize: 15,
                        height: 1.5,
                        color: subColor,
                      ),
                      isDark: isDark,
                    ),
                  ],
                )
                    .animate(delay: 100.ms)
                    .fade(duration: 250.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      curve: AppPhysics.houseSpringCurve,
                    ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCastStrip(item, isDark),
                    const SizedBox(height: 24),
                    _buildWatchProvidersSection(context, ref, item, isDark),
                  ],
                )
                    .animate(delay: 220.ms)
                    .fade(duration: 250.ms)
                    .slideY(
                      begin: 0.08,
                      end: 0,
                      curve: AppPhysics.houseSpringCurve,
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, MediaItem item, bool isDark) {
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: phColor,
            child: MediaImage(
              item: item,
              imageUrl: item.backdropUrl ?? item.posterUrl,
              fit: BoxFit.cover,
              showFallbackTitle: false,
            ),
          ),
          Center(
            child: PressableScale(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TrailerPlayer(item: item)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child:
                    const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(MediaItem item, bool isDark) {
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final textColor = isDark ? const Color(0xFF1A140C) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '★ ${item.rating.toStringAsFixed(1)}',
        style: AppThemes.safeGeist(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetaRow(MediaItem item, bool isDark) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    final metaPills = <Widget>[];

    // Rating badge
    metaPills.add(_buildRatingBadge(item, isDark));

    if (item.type == MediaType.movie) {
      if (item.runtime != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.schedule,
            '${item.runtime} min',
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.releaseOrAirDate != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.calendar_today,
            _formatDate(item.releaseOrAirDate!),
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
    } else {
      // TV show
      if (item.seasonsCount != null) {
        final seasonLabel = item.seasonsCount == 1
            ? '1 Season'
            : '${item.seasonsCount} Seasons';
        metaPills.add(
          _buildMetaPill(
            Icons.layers_outlined,
            seasonLabel,
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.episodesCount != null) {
        final episodeLabel = item.episodesCount == 1
            ? '1 Episode'
            : '${item.episodesCount} Episodes';
        metaPills.add(
          _buildMetaPill(
            Icons.video_library_outlined,
            episodeLabel,
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.nextEpisodeAirDate != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.upcoming_outlined,
            'Next: ${_formatDate(item.nextEpisodeAirDate!)}',
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
      if (item.releaseOrAirDate != null) {
        metaPills.add(
          _buildMetaPill(
            Icons.calendar_today,
            _formatDate(item.releaseOrAirDate!),
            phColor,
            lineRgba,
            subColor,
          ),
        );
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: metaPills,
    );
  }

  Widget _buildMetaPill(
    IconData icon,
    String text,
    Color bgColor,
    Color borderColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppThemes.safeGeist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChips(MediaItem item, bool isDark) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: item.genres.map((genre) {
        return PressableScale(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: phColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: lineRgba),
            ),
            child: Text(
              genre,
              style: AppThemes.safeGeist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, MediaItem item, bool isDark) {
    final mediaState = ref.watch(mediaProvider);
    final notifier = ref.read(mediaProvider.notifier);

    final inWatchlist = mediaState.watchlist.containsKey(item.id);
    final inMaybe = mediaState.maybeList.containsKey(item.id);
    final inWatched = mediaState.watchedList.containsKey(item.id);

    final watchColor =
        isDark ? AppColors.srStatusWatchlist : AppColors.rrStatusWatchlist;
    final saveColor =
        isDark ? AppColors.srStatusSave : AppColors.rrStatusSave;
    final watchedColor =
        isDark ? AppColors.srStatusWatched : AppColors.rrStatusWatched;

    return Row(
      children: [
        Expanded(
          child: _buildStatusToggle(
            'Watchlist',
            inWatchlist,
            watchColor,
            () => notifier.toggleWatchlist(item),
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusToggle(
            'Save',
            inMaybe,
            saveColor,
            () => notifier.toggleMaybe(item),
            isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusToggle(
            'Watched',
            inWatched,
            watchedColor,
            () => notifier.toggleWatched(item),
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(
    String label,
    bool isSelected,
    Color accentColor,
    VoidCallback onTap,
    bool isDark,
  ) {
    final textColor = isSelected
        ? (isDark ? const Color(0xFF1A140C) : Colors.white)
        : (isDark ? AppColors.srSub : AppColors.rrSub);
    final borderColor = isSelected
        ? accentColor
        : (isDark ? accentColor.withAlpha(50) : accentColor.withAlpha(50));

    final IconData iconData;
    if (label == 'Watchlist') {
      iconData = isSelected ? Icons.bookmark : Icons.bookmark_outline;
    } else if (label == 'Save') {
      iconData = isSelected ? Icons.star : Icons.star_border;
    } else {
      iconData = isSelected ? Icons.check_circle : Icons.check_circle_outline;
    }

    final decoration = isSelected
        ? (isDark
            ? BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.15),
                    blurRadius: 0,
                    spreadRadius: 0,
                    offset: Offset(0, 1),
                    blurStyle: BlurStyle.inner,
                  ),
                ],
              )
            : AppColors.primaryButtonDecoration(
                isDark: false,
                borderRadius: 12,
              ))
        : BoxDecoration(
            color: isDark ? const Color(0xFF100C0A) : const Color(0xFFE7DDC9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          );

    return StatusPulseRing(
      isSelected: isSelected,
      accentColor: accentColor,
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          height: 44,
          decoration: decoration,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppPhysics.houseSpringDuration,
                switchInCurve: AppPhysics.houseSpringCurve,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  iconData,
                  key: ValueKey('$label-$isSelected'),
                  size: 15,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: AppPhysics.houseSpringDuration,
                curve: AppPhysics.houseSpringCurve,
                style: AppThemes.safeGeist(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCastStrip(MediaItem item, bool isDark) {
    if (item.cast.isEmpty) return const SizedBox.shrink();

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cast',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: item.cast.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: phColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: lineRgba),
                      ),
                      child: Icon(Icons.person, color: subColor),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        item.cast[index],
                        style: AppThemes.safeGeist(
                          fontSize: 11,
                          color: subColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchProvidersSection(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
    bool isDark,
  ) {
    final mediaState = ref.watch(mediaProvider);
    final selectedCountry = mediaState.watchProvidersCountry;
    final notifier = ref.read(mediaProvider.notifier);

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    const supportedCountries = ['US', 'GB', 'CA', 'AU', 'DE', 'FR', 'JP'];
    final currentCountry = supportedCountries.contains(selectedCountry)
        ? selectedCountry
        : 'US';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Where to Watch',
              style: AppThemes.safeGeist(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: inkColor,
              ),
            ),
            PressableScale(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: phColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lineRgba),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentCountry,
                    dropdownColor: isDark ? AppColors.srCard : AppColors.rrCard,
                    icon: Icon(Icons.arrow_drop_down, color: subColor, size: 20),
                    isDense: true,
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: inkColor,
                    ),
                    onChanged: (String? newCountry) {
                      if (newCountry != null) {
                        notifier.setWatchProvidersCountry(newCountry);
                      }
                    },
                    items: supportedCountries
                        .map<DropdownMenuItem<String>>((String country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (item.watchProviders.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.watchProviders.map((provider) {
              return PressableScale(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: phColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: lineRgba),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tv, size: 14, color: accColor),
                      const SizedBox(width: 6),
                      Text(
                        provider,
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: inkColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ).animate(key: ValueKey(currentCountry)).fade(duration: 250.ms)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              'No streaming providers available in $currentCountry.',
              style: AppThemes.safeGeist(
                fontSize: 12.5,
                color: subColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ).animate(key: ValueKey(currentCountry)).fade(duration: 250.ms),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class StatusPulseRing extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final Color accentColor;

  const StatusPulseRing({
    super.key,
    required this.child,
    required this.isSelected,
    required this.accentColor,
  });

  @override
  State<StatusPulseRing> createState() => _StatusPulseRingState();
}

class _StatusPulseRingState extends State<StatusPulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppPhysics.houseSpringDuration,
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: AppPhysics.houseSpringCurve),
    );
    _pulseOpacity = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: AppPhysics.houseSpringCurve),
    );
  }

  @override
  void didUpdateWidget(StatusPulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_pulseController.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.accentColor, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}

class ExpandableOverviewText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool isDark;
  final int maxLinesCollapsed;

  const ExpandableOverviewText({
    super.key,
    required this.text,
    required this.style,
    required this.isDark,
    this.maxLinesCollapsed = 3,
  });

  @override
  State<ExpandableOverviewText> createState() => _ExpandableOverviewTextState();
}

class _ExpandableOverviewTextState extends State<ExpandableOverviewText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDark ? AppColors.srAcc : AppColors.rrAcc;

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.text, style: widget.style);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLinesCollapsed,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: AppPhysics.houseSpringCurve,
              alignment: Alignment.topCenter,
              child: Text(
                widget.text,
                style: widget.style,
                maxLines: _isExpanded ? null : widget.maxLinesCollapsed,
                overflow: _isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
              ),
            ),
            if (isOverflowing) ...[
              const SizedBox(height: 6),
              PressableScale(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Show less' : 'Show more',
                        style: AppThemes.safeGeist(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: AppPhysics.houseSpringCurve,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
