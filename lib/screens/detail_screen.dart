import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/media_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/media_item.dart';
import '../widgets/trailer_player.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'browse_screen.dart';

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
                return FullScreenErrorWidget(
                  message: 'Failed to load media details.',
                  onRetry: () => ref.invalidate(mediaDetailsProvider(id)),
                );
              }
              final isLarge = MediaQuery.of(context).size.width > 800;

              if (isLarge) {
                return _buildLargeLayout(context, ref, item, isDark);
              }
              return _buildCompactLayout(context, ref, item, isDark);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              final message = err.toString().replaceAll('Exception: ', '');
              return FullScreenErrorWidget(
                message: message.isNotEmpty
                    ? message
                    : 'Failed to load media details.',
                onRetry: () => ref.invalidate(mediaDetailsProvider(id)),
              );
            },
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
                    if (item.tagline != null && item.tagline!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${item.tagline}"',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: subColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildMetaRow(item, isDark),
                    if (item.genres.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildGenreChips(context, ref, item, isDark),
                    ],
                    if (item.belongsToCollection != null)
                      _buildCollectionBanner(item, isDark),
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
                    _buildDirectorOrCreatorCredit(item, isDark),
                    _buildCastStrip(item, isDark),
                    const SizedBox(height: 22),
                    _buildKeywordChips(context, ref, item, isDark),
                    _buildNetworksSection(item, isDark),
                    _buildProductionCompaniesSection(item, isDark),
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
                    if (item.tagline != null && item.tagline!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${item.tagline}"',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: subColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildMetaRow(item, isDark),
                    if (item.genres.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildGenreChips(context, ref, item, isDark),
                    ],
                    if (item.belongsToCollection != null)
                      _buildCollectionBanner(item, isDark),
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
                    _buildDirectorOrCreatorCredit(item, isDark),
                    _buildCastStrip(item, isDark),
                    const SizedBox(height: 24),
                    _buildKeywordChips(context, ref, item, isDark),
                    _buildNetworksSection(item, isDark),
                    _buildProductionCompaniesSection(item, isDark),
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

    final String ratingStr;
    if (item.voteCount != null && item.voteCount! > 0) {
      ratingStr = '★ ${item.rating.toStringAsFixed(1)} (${_formatVoteCount(item.voteCount!)})';
    } else {
      ratingStr = '★ ${item.rating.toStringAsFixed(1)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ratingStr,
        style: AppThemes.safeGeist(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  String _formatVoteCount(int count) {
    if (count >= 1000000) {
      final m = count / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}M votes';
    } else if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k votes';
    } else {
      return '$count votes';
    }
  }

  Widget _buildMetaRow(MediaItem item, bool isDark) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    final metaPills = <Widget>[];

    // Rating badge
    metaPills.add(_buildRatingBadge(item, isDark));

    // Certification badge
    if (item.certification != null && item.certification!.isNotEmpty) {
      metaPills.add(
        _buildMetaPill(
          Icons.verified_user_outlined,
          item.certification!,
          phColor,
          lineRgba,
          subColor,
        ),
      );
    }

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

  Widget _buildGenreChips(BuildContext context, WidgetRef ref, MediaItem item, bool isDark) {
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: item.genres.map((genre) {
        return PressableScale(
          onTap: () {
            ref.read(browseGenreProvider.notifier).setGenre(genre);
            ref.read(browseKeywordProvider.notifier).clearKeyword();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BrowseScreen()),
            );
          },
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

  Widget _buildKeywordChips(BuildContext context, WidgetRef ref, MediaItem item, bool isDark) {
    if (item.keywords == null || item.keywords!.isEmpty) {
      return const SizedBox.shrink();
    }

    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Keywords',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: item.keywords!.map((kw) {
            return PressableScale(
              onTap: () {
                ref.read(browseKeywordProvider.notifier).setKeyword(kw.name);
                ref.read(browseGenreProvider.notifier).setGenre('All');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BrowseScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: phColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: lineRgba),
                ),
                child: Text(
                  '#${kw.name}',
                  style: AppThemes.safeGeist(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: subColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCollectionBanner(MediaItem item, bool isDark) {
    final collection = item.belongsToCollection;
    if (collection == null) return const SizedBox.shrink();

    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final cardBg = isDark ? AppColors.srCard : AppColors.rrCard;

    final imageUrl = collection.backdropUrl ?? collection.posterUrl;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineRgba),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (imageUrl != null)
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark
                        ? const Color(0xD9000000)
                        : const Color(0xB3000000),
                    isDark
                        ? const Color(0x80000000)
                        : const Color(0x66000000),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (collection.posterUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      collection.posterUrl!,
                      width: 48,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 72,
                        color: phColor,
                        child: const Icon(Icons.movie, color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLLECTION',
                        style: AppThemes.safeGeist(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? AppColors.srAcc : AppColors.rrAcc,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Part of the ${collection.name}',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDirectorOrCreatorCredit(MediaItem item, bool isDark) {
    final String? label;
    final String? names;

    if (item.director != null && item.director!.isNotEmpty) {
      label = 'Director';
      names = item.director;
    } else if (item.createdBy != null && item.createdBy!.isNotEmpty) {
      label = 'Created by';
      names = item.createdBy!.join(', ');
    } else {
      return const SizedBox.shrink();
    }

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: phColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lineRgba),
      ),
      child: Row(
        children: [
          Icon(Icons.video_camera_front_outlined, size: 20, color: subColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppThemes.safeGeist(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                names!,
                style: AppThemes.safeGeist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: inkColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworksSection(MediaItem item, bool isDark) {
    if (item.networks == null || item.networks!.isEmpty) {
      return const SizedBox.shrink();
    }

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Networks',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: item.networks!.map((net) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: phColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lineRgba),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (net.logoUrl != null && net.logoUrl!.isNotEmpty) ...[
                    Image.network(
                      net.logoUrl!,
                      height: 16,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.tv, size: 16, color: subColor),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(Icons.tv, size: 16, color: subColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    net.name,
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: inkColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProductionCompaniesSection(MediaItem item, bool isDark) {
    if (item.productionCompanies == null || item.productionCompanies!.isEmpty) {
      return const SizedBox.shrink();
    }

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Production Companies',
          style: AppThemes.safeGeist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: inkColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: item.productionCompanies!.map((pc) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: phColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lineRgba),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pc.logoUrl != null && pc.logoUrl!.isNotEmpty) ...[
                    Image.network(
                      pc.logoUrl!,
                      height: 16,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.business, size: 16, color: subColor),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(Icons.business, size: 16, color: subColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    pc.name,
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: inkColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        if (item.imdbId != null && item.imdbId!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImdbButton(item, isDark),
        ],
      ],
    );
  }

  Widget _buildImdbButton(MediaItem item, bool isDark) {
    if (item.imdbId == null || item.imdbId!.isEmpty) {
      return const SizedBox.shrink();
    }

    return PressableScale(
      onTap: () async {
        final url = Uri.parse('https://www.imdb.com/title/${item.imdbId}');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2419) : const Color(0xFFF0E5D8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C518), // IMDb Yellow
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'IMDb',
                style: AppThemes.safeGeist(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'View on IMDb',
              style: AppThemes.safeGeist(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.srInk : AppColors.rrInk,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              size: 14,
              color: isDark ? AppColors.srSub : AppColors.rrSub,
            ),
          ],
        ),
      ),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
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
              final castName = item.cast[index];
              final castMember = (index < item.castMembers.length)
                  ? item.castMembers[index]
                  : null;
              final profileUrl = castMember?.profileUrl;

              Widget avatarContent;
              if (profileUrl != null && profileUrl.isNotEmpty) {
                avatarContent = ClipOval(
                  child: Image.network(
                    profileUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person, color: subColor),
                  ),
                );
              } else {
                avatarContent = Icon(Icons.person, color: subColor);
              }

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
                      child: avatarContent,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        castName,
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
    final regionsAsync = ref.watch(watchProviderRegionsProvider);

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    final defaultRegions = const [
      {'code': 'US', 'name': 'United States'},
      {'code': 'GB', 'name': 'United Kingdom'},
      {'code': 'CA', 'name': 'Canada'},
      {'code': 'AU', 'name': 'Australia'},
      {'code': 'DE', 'name': 'Germany'},
      {'code': 'FR', 'name': 'France'},
      {'code': 'JP', 'name': 'Japan'},
    ];

    final availableRegions = regionsAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : defaultRegions,
      orElse: () => defaultRegions,
    );

    final hasSelected = availableRegions.any((r) => r['code'] == selectedCountry);
    final currentCountry = hasSelected
        ? selectedCountry
        : (availableRegions.isNotEmpty ? availableRegions.first['code']! : 'US');

    final countryProviders = item.getWatchProvidersForCountry(currentCountry);

    final grouped = <String, List<WatchProviderInfo>>{};
    for (final p in countryProviders) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

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
                    items: availableRegions
                        .map<DropdownMenuItem<String>>((region) {
                      final code = region['code'] ?? 'US';
                      return DropdownMenuItem<String>(
                        value: code,
                        child: Text(code),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (countryProviders.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final cat in ['Stream', 'Rent', 'Buy'])
                if (grouped.containsKey(cat) && grouped[cat]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 6),
                    child: Text(
                      cat,
                      style: AppThemes.safeGeist(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: grouped[cat]!.map((provider) {
                      return PressableScale(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: phColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: lineRgba),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat == 'Stream'
                                    ? Icons.tv
                                    : (cat == 'Rent'
                                        ? Icons.shopping_bag_outlined
                                        : Icons.shopping_cart_outlined),
                                size: 14,
                                color: accColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                provider.providerName,
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
                  ),
                  const SizedBox(height: 8),
                ],
            ],
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
