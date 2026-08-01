import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/movie_repository.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: isLarge ? _buildLargeLayout(repo) : _buildCompactLayout(repo),
    );
  }

  Widget _buildCompactLayout(MovieRepository repo) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(child: _buildGrid(repo)),
      ],
    );
  }

  Widget _buildLargeLayout(MovieRepository repo) {
    return Row(
      children: [
        Expanded(child: _buildGrid(repo)),
        const VerticalDivider(width: 1, thickness: 1),
        SizedBox(
          width: 250,
          child: _buildFilterPanel(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(genre),
              selected: _selectedGenre == genre,
              onSelected: (selected) {
                if (selected) setState(() => _selectedGenre = genre);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const Text('Genre'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _genres.map((genre) {
              return ChoiceChip(
                label: Text(genre),
                selected: _selectedGenre == genre,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedGenre = genre);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(MovieRepository repo) {
    return FutureBuilder<List<MediaItem>>(
      future: repo.getPopularMovies(), // Just an example fetch
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading media.'));
        }

        final items = snapshot.data!.where((item) {
          if (_selectedGenre == 'All') return true;
          return item.genres.contains(_selectedGenre);
        }).toList();

        if (items.isEmpty) {
          return const Center(child: Text('No media found matching filters.'));
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
      },
    );
  }
}
