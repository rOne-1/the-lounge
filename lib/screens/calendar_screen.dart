import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  Map<DateTime, List<MediaItem>> _groupedItems = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgenda();
  }

  Future<void> _loadAgenda() async {
    final repo = ref.read(movieRepositoryProvider);
    final movies = await repo.getTrendingMovies();
    final tvShows = await repo.getTrendingTvShows();

    final allItems = [...movies, ...tvShows]
        .where((m) => m.releaseOrAirDate != null)
        .toList();

    // Group by Date (ignoring time)
    final Map<DateTime, List<MediaItem>> grouped = {};
    for (final item in allItems) {
      final date = item.releaseOrAirDate!;
      final dateKey = DateTime(date.year, date.month, date.day);
      grouped.putIfAbsent(dateKey, () => []).add(item);
    }

    if (mounted) {
      setState(() {
        _groupedItems = grouped;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groupedItems.isEmpty) {
      return const Center(child: Text('No upcoming releases.'));
    }

    final sortedDates = _groupedItems.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final items = _groupedItems[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...items.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: item.posterUrl != null
                        ? Image.network(item.posterUrl!,
                            width: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(width: 40, color: Colors.grey))
                        : const Icon(Icons.movie),
                    title: Text(item.title),
                    subtitle: Text(
                        item.type == MediaType.movie ? 'Movie' : 'TV Show'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DetailScreen(id: item.id)),
                    ),
                  ),
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
