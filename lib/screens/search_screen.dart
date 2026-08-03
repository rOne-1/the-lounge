import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  List<MediaItem>? _results;
  bool _loading = false;
  Object? _searchError;

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _query = '';
        _results = null;
        _loading = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _query = query.trim();
      _loading = true;
      _searchError = null;
    });

    try {
      final repo = ref.read(movieRepositoryProvider);
      final results = await repo.searchMedia(_query);

      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;

    final isLarge = MediaQuery.of(context).size.width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              isLarge ? 24.0 : 18.0, isLarge ? 4.0 : 18.0, isLarge ? 24.0 : 18.0, 18.0),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: phColor,
              border: Border.all(color: lineRgba),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: subColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppThemes.safeGeist(fontSize: 14, color: inkColor),
                    decoration: InputDecoration(
                      hintText: 'Movies, TV shows, cast...',
                      hintStyle: AppThemes.safeGeist(fontSize: 14, color: subColor),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      _onSearch(val);
                    },
                  ),
                ),
                if (_query.isNotEmpty)
                  PressableScale(
                    onTap: () {
                      _controller.clear();
                      _onSearch('');
                    },
                    child: Icon(Icons.close, color: subColor, size: 20),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _buildBody(isDark, inkColor, subColor, lineRgba, phColor, accColor),
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark, Color inkColor, Color subColor, Color lineRgba, Color phColor, Color accColor) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      final errorMessage = _searchError.toString().replaceAll('Exception: ', '');
      return FullScreenErrorWidget(
        message: errorMessage.isNotEmpty
            ? errorMessage
            : 'Failed to perform search. Please check your connection.',
        onRetry: () => _onSearch(_query),
      );
    }

    if (_query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 48, color: subColor),
            const SizedBox(height: 16),
            Text('Search across the catalog',
                style: AppThemes.safeGeist(color: subColor, fontSize: 15)),
          ],
        ),
      );
    }

    if (_results != null && _results!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: subColor),
              const SizedBox(height: 16),
              Text(
                'No results found for "$_query"',
                textAlign: TextAlign.center,
                style: AppThemes.safeGeist(
                    color: inkColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Check spelling or try searching for another title or actor.',
                textAlign: TextAlign.center,
                style: AppThemes.safeGeist(color: subColor, fontSize: 13),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  _controller.clear();
                  _onSearch('');
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear search'),
              ),
            ],
          ),
        ),
      );
    }

    if (_results != null) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(18, 0, 18, 18.0 + MediaQuery.of(context).padding.bottom),
        itemCount: _results!.length,
        separatorBuilder: (_, __) => Divider(color: lineRgba, height: 1),
        itemBuilder: (context, index) {
          final item = _results![index];
          final isTitleMatch = item.title.toLowerCase().contains(_query.toLowerCase());

          return PressableScale(
            child: OpenContainer(
              transitionDuration: AppPhysics.houseSpringDuration,
              closedElevation: 0,
              openElevation: 0,
              closedColor: Colors.transparent,
              openColor: isDark ? AppColors.srBase : AppColors.rrBase,
              middleColor: Colors.transparent,
              closedShape: const RoundedRectangleBorder(),
              closedBuilder: (context, openContainer) {
                return InkWell(
                  onTap: openContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 66,
                          decoration: BoxDecoration(
                            color: phColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: MediaImage(
                            item: item,
                            fit: BoxFit.cover,
                            showFallbackTitle: false,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: AppThemes.safeGeist(fontSize: 15, fontWeight: FontWeight.w500, color: inkColor)),
                              const SizedBox(height: 4),
                              if (!isTitleMatch && item.cast.isNotEmpty)
                                _buildCastHighlight(item.cast, _query, inkColor, subColor)
                              else
                                Text('2024 · ${item.genres.join(', ')}', style: AppThemes.safeGeist(fontSize: 13, color: subColor)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: subColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
              openBuilder: (context, _) => DetailScreen(id: item.prefixedId),
            ),
          ).animate().fade(duration: 250.ms).slideY(
              begin: 0.1,
              end: 0,
              delay: (index.clamp(0, 5) * 40).ms);
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCastHighlight(List<String> cast, String query, Color inkColor, Color subColor) {
    final lowerQuery = query.toLowerCase();
    final List<TextSpan> spans = [];
    
    for (int i = 0; i < cast.length; i++) {
      final actor = cast[i];
      final isMatch = actor.toLowerCase().contains(lowerQuery);
      
      spans.add(TextSpan(
        text: actor + (i == cast.length - 1 ? '' : ', '),
        style: TextStyle(
          color: isMatch ? inkColor : subColor,
          fontWeight: isMatch ? FontWeight.w600 : FontWeight.w400,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(
        style: AppThemes.safeGeist(fontSize: 13),
        children: spans,
      ),
    );
  }
}
