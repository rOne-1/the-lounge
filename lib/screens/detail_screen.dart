import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_provider.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';
import '../widgets/trailer_player.dart';

class DetailScreen extends ConsumerWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(movieRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
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
            return _buildLargeLayout(context, ref, item);
          }
          return _buildCompactLayout(context, ref, item);
        },
      ),
    );
  }

  Widget _buildCompactLayout(
      BuildContext context, WidgetRef ref, MediaItem item) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(context, item),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                _buildActionButtons(ref, item),
                const SizedBox(height: 16),
                Text(item.overview),
                const SizedBox(height: 16),
                _buildCastStrip(item),
                const SizedBox(height: 16),
                _buildWatchProviders(item),
                const SizedBox(height: 16),
                _buildCalendarButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeLayout(
      BuildContext context, WidgetRef ref, MediaItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: _buildHero(context, item),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 24),
                _buildActionButtons(ref, item),
                const SizedBox(height: 24),
                Text(item.overview,
                    style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                _buildCastStrip(item),
                const SizedBox(height: 24),
                _buildWatchProviders(item),
                const SizedBox(height: 24),
                _buildCalendarButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, MediaItem item) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.backdropUrl ?? item.posterUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey),
          ),
          Center(
            child: IconButton(
              iconSize: 64,
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TrailerPlayer(item: item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(WidgetRef ref, MediaItem item) {
    final mediaState = ref.watch(mediaProvider);
    final notifier = ref.read(mediaProvider.notifier);

    final inWatchlist = mediaState.watchlist.containsKey(item.id);
    final inMaybe = mediaState.maybeList.containsKey(item.id);
    final inWatched = mediaState.watchedList.containsKey(item.id);

    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Watchlist'),
          selected: inWatchlist,
          onSelected: (_) => notifier.addToWatchlist(item),
        ),
        FilterChip(
          label: const Text('Maybe'),
          selected: inMaybe,
          onSelected: (_) => notifier.addToMaybeList(item),
        ),
        FilterChip(
          label: const Text('Watched'),
          selected: inWatched,
          onSelected: (_) => notifier.addToWatchedList(item),
        ),
      ],
    );
  }

  Widget _buildCastStrip(MediaItem item) {
    if (item.cast.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cast',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: item.cast.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 30, child: Icon(Icons.person)),
                    const SizedBox(height: 4),
                    Text(item.cast[index],
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWatchProviders(MediaItem item) {
    if (item.watchProviders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available On',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: item.watchProviders
              .map((provider) => Chip(label: Text(provider)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildCalendarButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.calendar_today),
      label: const Text('Add to Calendar'),
    );
  }
}
