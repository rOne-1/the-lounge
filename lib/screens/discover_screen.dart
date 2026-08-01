import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../providers/repository_provider.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  List<MediaItem> _pool = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPool();
  }

  Future<void> _loadPool() async {
    final repo = ref.read(movieRepositoryProvider);
    final trending = await repo.getTrendingMovies();
    final popular = await repo.getPopularMovies();
    if (mounted) {
      setState(() {
        _pool = <MediaItem>{...trending, ...popular}.toList(); // naive dedupe
        _loading = false;
      });
    }
  }

  void _onSwipe(MediaItem item, String direction) {
    final notifier = ref.read(mediaProvider.notifier);
    if (direction == 'Left') {
      // Skip
    } else if (direction == 'Right') {
      notifier.addToMaybeList(item);
    } else if (direction == 'Down') {
      notifier.addToWatchlist(item);
    } else if (direction == 'Up') {
      notifier.addToWatchedList(item);
    }

    setState(() {
      _pool.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pool.isEmpty) {
      return const Center(child: Text('You have seen all recommendations!'));
    }

    final isLarge = MediaQuery.of(context).size.width > 800;

    return isLarge ? _buildLargeLayout() : _buildCompactLayout();
  }

  Widget _buildCompactLayout() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
              'Swipe Legend: ← Skip | → Maybe | ↓ Watchlist | ↑ Watched',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: _pool.reversed.map((item) {
              final isTop = item.id == _pool.first.id;
              return SwipeCard(
                key: ValueKey(item.id),
                item: item,
                isInteractive: isTop,
                onSwipe: (dir) => _onSwipe(item, dir),
              );
            }).toList(),
          ),
        ),
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLargeLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                    'Swipe Legend: ← Skip | → Maybe | ↓ Watchlist | ↑ Watched',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: _pool.reversed.map((item) {
                    final isTop = item.id == _pool.first.id;
                    return SwipeCard(
                      key: ValueKey(item.id),
                      item: item,
                      isInteractive: isTop,
                      onSwipe: (dir) => _onSwipe(item, dir),
                    );
                  }).toList(),
                ),
              ),
              _buildActionButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildDetailsPanel(_pool.first),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsPanel(MediaItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text('Rating: ${item.rating}/10'),
        const SizedBox(height: 16),
        Text(item.overview),
        const SizedBox(height: 16),
        if (item.genres.isNotEmpty) ...[
          const Text('Genres', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: item.genres.map((g) => Chip(label: Text(g))).toList(),
          ),
        ]
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'btnSkip',
            onPressed: () => _onSwipe(_pool.first, 'Left'),
            backgroundColor: Colors.red.shade100,
            child: const Icon(Icons.close, color: Colors.red),
          ),
          FloatingActionButton(
            heroTag: 'btnWatchlist',
            onPressed: () => _onSwipe(_pool.first, 'Down'),
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.bookmark, color: Colors.blue),
          ),
          FloatingActionButton(
            heroTag: 'btnMaybe',
            onPressed: () => _onSwipe(_pool.first, 'Right'),
            backgroundColor: Colors.orange.shade100,
            child: const Icon(Icons.star, color: Colors.orange),
          ),
          FloatingActionButton(
            heroTag: 'btnWatched',
            onPressed: () => _onSwipe(_pool.first, 'Up'),
            backgroundColor: Colors.green.shade100,
            child: const Icon(Icons.check, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

class SwipeCard extends StatefulWidget {
  final MediaItem item;
  final bool isInteractive;
  final Function(String) onSwipe;

  const SwipeCard({
    super.key,
    required this.item,
    required this.isInteractive,
    required this.onSwipe,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  Offset _dragOffset = Offset.zero;
  double _angle = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 600 ? 400.0 : size.width * 0.8;
    final cardHeight = cardWidth * 1.5;

    Widget card = Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.item.posterUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.item.genres.join(', '),
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.isInteractive) {
      return card;
    }

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _dragOffset += details.delta;
          _angle = _dragOffset.dx / 300 * (math.pi / 8);
        });
      },
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        if (_dragOffset.dx > 100 || velocity.dx > 500) {
          widget.onSwipe('Right');
        } else if (_dragOffset.dx < -100 || velocity.dx < -500) {
          widget.onSwipe('Left');
        } else if (_dragOffset.dy > 100 || velocity.dy > 500) {
          widget.onSwipe('Down');
        } else if (_dragOffset.dy < -100 || velocity.dy < -500) {
          widget.onSwipe('Up');
        } else {
          setState(() {
            _dragOffset = Offset.zero;
            _angle = 0;
          });
        }
      },
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: _angle,
          child: card,
        ),
      ),
    );
  }
}
