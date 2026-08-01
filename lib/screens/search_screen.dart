import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search movies, TV shows, or cast...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _onSearch('');
                      },
                    )
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) {
              // Debounce could be added here
            },
            onSubmitted: _onSearch,
          ),
        ),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Type to search',
                style: TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      );
    }

    if (_results != null && _results!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No results found',
                style: TextStyle(color: Colors.grey, fontSize: 18)),
          ],
        ),
      );
    }

    if (_results != null) {
      return ListView.builder(
        itemCount: _results!.length,
        itemBuilder: (context, index) {
          final item = _results![index];
          final isTitleMatch =
              item.title.toLowerCase().contains(_query.toLowerCase());

          return ListTile(
            leading: item.posterUrl != null
                ? Image.network(item.posterUrl!,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(width: 50, color: Colors.grey))
                : Container(width: 50, color: Colors.grey),
            title: Text(item.title),
            subtitle: !isTitleMatch && item.cast.isNotEmpty
                ? _buildCastHighlight(item.cast, _query)
                : Text(item.genres.join(', ')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(id: item.id)),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCastHighlight(List<String> cast, String query) {
    final lowerQuery = query.toLowerCase();
    return Wrap(
      spacing: 4,
      children: cast.map((actor) {
        final isMatch = actor.toLowerCase().contains(lowerQuery);
        return Text(
          actor + (actor == cast.last ? '' : ','),
          style: TextStyle(
            color: isMatch ? Colors.blue : Colors.grey.withAlpha(128),
            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
