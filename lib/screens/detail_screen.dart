import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_provider.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';
import '../widgets/trailer_player.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailScreen extends ConsumerWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(movieRepositoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.srBase : AppColors.rrBase;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;

    return Scaffold(
      backgroundColor: baseColor,
      appBar: AppBar(
        title: Text('Details', style: GoogleFonts.bodoniModa(fontStyle: FontStyle.italic, color: inkColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: inkColor),
      ),
      body: FutureBuilder<MediaItem?>(
        future: repo.getMediaDetails(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load details.'));
          }

          final item = snapshot.data!;
          final isLarge = MediaQuery.of(context).size.width > 800;

          if (isLarge) {
            return _buildLargeLayout(context, ref, item, isDark);
          }
          return _buildCompactLayout(context, ref, item, isDark);
        },
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, WidgetRef ref, MediaItem item, bool isDark) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(context, item, isDark),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.bodoniModa(fontSize: 30, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: inkColor, height: 1.05)),
                const SizedBox(height: 18),
                _buildActionButtons(ref, item, isDark),
                const SizedBox(height: 22),
                Text(item.overview, style: AppThemes.safeGeist(fontSize: 14, height: 1.5, color: subColor)),
                const SizedBox(height: 22),
                _buildCastStrip(item, isDark),
                const SizedBox(height: 22),
                _buildWatchProviders(item, isDark, subColor, inkColor),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeLayout(BuildContext context, WidgetRef ref, MediaItem item, bool isDark) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: _buildHero(context, item, isDark),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: GoogleFonts.bodoniModa(fontSize: 34, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: inkColor, height: 1.05)),
                const SizedBox(height: 24),
                _buildActionButtons(ref, item, isDark),
                const SizedBox(height: 24),
                Text(item.overview, style: AppThemes.safeGeist(fontSize: 15, height: 1.5, color: subColor)),
                const SizedBox(height: 24),
                _buildCastStrip(item, isDark),
                const SizedBox(height: 24),
                _buildWatchProviders(item, isDark, subColor, inkColor),
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
            child: Image.network(
              item.backdropUrl ?? item.posterUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: phColor),
            ),
          ),
          Center(
            child: GestureDetector(
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
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, MediaItem item, bool isDark) {
    final mediaState = ref.watch(mediaProvider);
    final notifier = ref.read(mediaProvider.notifier);

    final inWatchlist = mediaState.watchlist.containsKey(item.id);
    final inMaybe = mediaState.maybeList.containsKey(item.id);
    final inWatched = mediaState.watchedList.containsKey(item.id);

    final watchColor = isDark ? AppColors.srStatusWatchlist : AppColors.rrStatusWatchlist;
    final saveColor = isDark ? AppColors.srStatusSave : AppColors.rrStatusSave;
    final watchedColor = isDark ? AppColors.srStatusWatched : AppColors.rrStatusWatched;

    return Row(
      children: [
        Expanded(
          child: _buildStatusToggle(
            'Watchlist',
            inWatchlist,
            watchColor,
            () => notifier.addToWatchlist(item),
            isDark
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusToggle(
            'Save',
            inMaybe,
            saveColor,
            () => notifier.addToMaybeList(item),
            isDark
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusToggle(
            'Watched',
            inWatched,
            watchedColor,
            () => notifier.addToWatchedList(item),
            isDark
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(String label, bool isSelected, Color accentColor, VoidCallback onTap, bool isDark) {
    final bgColor = isSelected ? accentColor : (isDark ? const Color(0xFF100C0A) : const Color(0xFFE7DDC9));
    final textColor = isSelected ? (isDark ? const Color(0xFF1A140C) : Colors.white) : (isDark ? AppColors.srSub : AppColors.rrSub);
    final borderColor = isSelected ? accentColor : (isDark ? accentColor.withAlpha(50) : accentColor.withAlpha(50));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isSelected ? [BoxShadow(color: isDark ? const Color.fromRGBO(0, 0, 0, 0.15) : const Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1), blurStyle: BlurStyle.inner)] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppThemes.safeGeist(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, color: textColor),
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
        Text('Cast', style: AppThemes.safeGeist(fontSize: 15, fontWeight: FontWeight.w600, color: inkColor)),
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
                      width: 60, height: 60,
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
                        style: AppThemes.safeGeist(fontSize: 11, color: subColor),
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

  Widget _buildWatchProviders(MediaItem item, bool isDark, Color subColor, Color inkColor) {
    if (item.watchProviders.isEmpty) return const SizedBox.shrink();
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available On', style: AppThemes.safeGeist(fontSize: 15, fontWeight: FontWeight.w600, color: inkColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: item.watchProviders.map((provider) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: phColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: lineRgba),
            ),
            child: Text(provider, style: AppThemes.safeGeist(fontSize: 12, color: inkColor)),
          )).toList(),
        ),
      ],
    );
  }
}
