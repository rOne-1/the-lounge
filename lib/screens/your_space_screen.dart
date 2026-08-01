import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';

class YourSpaceScreen extends ConsumerWidget {
  const YourSpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Watchlist'),
              Tab(text: 'Maybe'),
              Tab(text: 'Watched'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGrid(mediaState.watchlist.values.toList()),
                _buildGrid(mediaState.maybeList.values.toList()),
                _buildGrid(mediaState.watchedList.values.toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<MediaItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing here yet.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(id: item.id)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.posterUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
