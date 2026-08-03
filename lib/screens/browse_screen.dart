import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/repository_provider.dart';
import 'detail_screen.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/drag_to_dismiss_sheet.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  String _selectedGenre = 'All';
  final List<String> _genres = [
    'All',
    'Action',
    'Sci-Fi',
    'Thriller',
    'Drama',
    'Comedy'
  ];

  void _showFilterBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final cardBg = isDark ? AppColors.srCard : AppColors.rrCard;
        final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
        final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

        return DragToDismissSheet(
          isDark: isDark,
          onDismiss: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              32.0 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba,
                ),
              ),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter catalog',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            color: inkColor,
                          ),
                        ),
                        PressableScale(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.close, color: subColor, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Genre',
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: inkColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _genres.map((genre) {
                        final isSelected = _selectedGenre == genre;
                        return PressableScale(
                          onTap: () {
                            setState(() => _selectedGenre = genre);
                            setSheetState(() {});
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.05 : 1.0,
                            duration: AppPhysics.houseSpringDuration,
                            curve: AppPhysics.houseSpringCurve,
                            child: AnimatedContainer(
                              duration: AppPhysics.houseSpringDuration,
                              curve: AppPhysics.houseSpringCurve,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: isSelected
                                  ? AppColors.primaryButtonDecoration(
                                      isDark: isDark, borderRadius: 999)
                                  : BoxDecoration(
                                      color: isDark
                                          ? AppColors.srPill
                                          : AppColors.rrPill,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.srLineRgba
                                            : AppColors.rrLineRgba,
                                      ),
                                    ),
                              child: Text(
                                genre,
                                style: GoogleFonts.getFont(
                                  'Geist',
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? (isDark
                                          ? const Color(0xFF1A140C)
                                          : Colors.white)
                                      : inkColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    PressableScale(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: AppColors.primaryButtonDecoration(
                          isDark: isDark,
                          borderRadius: 12,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Apply Filters',
                          style: AppThemes.safeGeist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF1A140C)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = MediaQuery.of(context).size.width > 800;
    
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
            title: Text('Browse', style: GoogleFonts.bodoniModa(fontStyle: FontStyle.italic, color: inkColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: inkColor),
            actions: [
              PressableScale(
                onTap: () => _showFilterBottomSheet(context, isDark),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.filter_list, color: inkColor, size: 22),
                ),
              ),
            ],
          ),
          body: isLarge ? _buildLargeLayout(isDark) : _buildCompactLayout(isDark),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(bool isDark) {
    return Column(
      children: [
        _buildFilterBar(isDark),
        Expanded(child: _buildGrid(isDark)),
      ],
    );
  }

  Widget _buildLargeLayout(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildGrid(isDark)),
        VerticalDivider(width: 1, thickness: 1, color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba),
        SizedBox(
          width: 250,
          child: _buildFilterPanel(isDark),
        ),
      ],
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final pillColor = isDark ? AppColors.srPill : AppColors.rrPill;
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          final isSelected = _selectedGenre == genre;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: PressableScale(
              onTap: () {
                setState(() => _selectedGenre = genre);
              },
              child: AnimatedScale(
                scale: isSelected ? 1.05 : 1.0,
                duration: AppPhysics.houseSpringDuration,
                curve: AppPhysics.houseSpringCurve,
                child: AnimatedContainer(
                  duration: AppPhysics.houseSpringDuration,
                  curve: AppPhysics.houseSpringCurve,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: isSelected
                      ? AppColors.primaryButtonDecoration(
                          isDark: isDark, borderRadius: 999)
                      : BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: lineRgba),
                        ),
                  alignment: Alignment.center,
                  child: Text(
                    genre,
                    style: GoogleFonts.getFont(
                      'Geist',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? (isDark ? const Color(0xFF1A140C) : Colors.white) : inkColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(bool isDark) {
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final pillColor = isDark ? AppColors.srPill : AppColors.rrPill;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: AppThemes.safeGeist(fontSize: 15, fontWeight: FontWeight.w600, color: inkColor)),
          const SizedBox(height: 16),
          Text('Genre', style: AppThemes.safeGeist(fontSize: 13, color: inkColor)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) {
              final isSelected = _selectedGenre == genre;
              return PressableScale(
                onTap: () {
                  setState(() => _selectedGenre = genre);
                },
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: AppPhysics.houseSpringDuration,
                  curve: AppPhysics.houseSpringCurve,
                  child: AnimatedContainer(
                    duration: AppPhysics.houseSpringDuration,
                    curve: AppPhysics.houseSpringCurve,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: isSelected
                        ? AppColors.primaryButtonDecoration(
                            isDark: isDark, borderRadius: 999)
                        : BoxDecoration(
                            color: pillColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: lineRgba),
                          ),
                    child: Text(
                      genre,
                      style: GoogleFonts.getFont(
                        'Geist',
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? (isDark ? const Color(0xFF1A140C) : Colors.white) : inkColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    final popularAsync = ref.watch(popularMoviesProvider);

    return popularAsync.when(
      data: (allItems) {
        final items = allItems.where((item) {
          if (_selectedGenre == 'All') return true;
          return item.genres.contains(_selectedGenre);
        }).toList();

        if (items.isEmpty) {
          return Center(
              child: Text('No media found matching filters.',
                  style: AppThemes.safeGeist(color: subColor)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(18),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            childAspectRatio: 2 / 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return PressableScale(
              child: OpenContainer(
                transitionDuration: AppPhysics.houseSpringDuration,
                closedElevation: 0,
                openElevation: 0,
                closedColor: Colors.transparent,
                openColor: isDark ? AppColors.srBase : AppColors.rrBase,
                middleColor: Colors.transparent,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                closedBuilder: (context, openContainer) {
                  return GestureDetector(
                    onTap: openContainer,
                    child: Container(
                      decoration: BoxDecoration(
                        color: phColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: lineRgba),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: MediaImage(
                        item: item,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
                openBuilder: (context, _) => DetailScreen(id: item.id),
              ),
            ).animate().fade(duration: 250.ms).slideY(
                begin: 0.1,
                end: 0,
                delay: (index.clamp(0, 5) * 40).ms);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
          child: Text('Error loading media.',
              style: AppThemes.safeGeist(color: subColor))),
    );
  }
}
