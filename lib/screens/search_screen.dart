import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import '../widgets/fallback_widgets.dart';

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

  void _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _query = '';
        _results = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _query = query.trim();
      _loading = true;
    });

    final repo = ref.read(movieRepositoryProvider);
    final results = await repo.searchMedia(_query);

    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
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

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
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
                    GestureDetector(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No results found for "$_query"',
                style: AppThemes.safeGeist(color: subColor, fontSize: 15)),
          ],
        ),
      );
    }

    if (_results != null) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: _results!.length,
        separatorBuilder: (_, __) => Divider(color: lineRgba, height: 1),
        itemBuilder: (context, index) {
          final item = _results![index];
          final isTitleMatch = item.title.toLowerCase().contains(_query.toLowerCase());

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(id: item.id)),
            ),
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
