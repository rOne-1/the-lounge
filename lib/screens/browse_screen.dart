import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/movie_repository.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/fallback_widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(movieRepositoryProvider);
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
          ),
          body: isLarge ? _buildLargeLayout(repo, isDark) : _buildCompactLayout(repo, isDark),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(MovieRepository repo, bool isDark) {
    return Column(
      children: [
        _buildFilterBar(isDark),
        Expanded(child: _buildGrid(repo, isDark)),
      ],
    );
  }

  Widget _buildLargeLayout(MovieRepository repo, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildGrid(repo, isDark)),
        VerticalDivider(width: 1, thickness: 1, color: isDark ? AppColors.srLineRgba : AppColors.rrLineRgba),
        SizedBox(
          width: 250,
          child: _buildFilterPanel(isDark),
        ),
      ],
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
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
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedGenre = genre);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? accColor : pillColor,
                  borderRadius: BorderRadius.circular(999),
                  border: isSelected ? null : Border.all(color: lineRgba),
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
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(bool isDark) {
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
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
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedGenre = genre);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? accColor : pillColor,
                    borderRadius: BorderRadius.circular(999),
                    border: isSelected ? null : Border.all(color: lineRgba),
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(MovieRepository repo, bool isDark) {
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;

    return FutureBuilder<List<MediaItem>>(
      future: repo.getPopularMovies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Error loading media.', style: AppThemes.safeGeist(color: subColor)));
        }

        final items = snapshot.data!.where((item) {
          if (_selectedGenre == 'All') return true;
          return item.genres.contains(_selectedGenre);
        }).toList();

        if (items.isEmpty) {
          return Center(child: Text('No media found matching filters.', style: AppThemes.safeGeist(color: subColor)));
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
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailScreen(id: item.id)),
              ),
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
        );
      },
    );
  }
}
