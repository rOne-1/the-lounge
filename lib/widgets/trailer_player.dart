import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/media_item.dart';
import 'fallback_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/media_provider.dart';

class TrailerPlayer extends ConsumerStatefulWidget {
  final MediaItem item;

  const TrailerPlayer({super.key, required this.item});

  @override
  ConsumerState<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends ConsumerState<TrailerPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: 'dQw4w9WgXcQ', // Placeholder
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      _controller.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.item.hasTrailer) {
      return PlaybackUnavailableWidget(
        title: widget.item.title,
        onAddWatchlist: () {
          ref.read(mediaProvider.notifier).addToWatchlist(widget.item);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to Watchlist')),
          );
        },
      );
    }

    final isYoutubePlatform =
        kIsWeb || defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (isYoutubePlatform)
            Center(
              child: YoutubePlayer(
                controller: _controller,
                aspectRatio: 16 / 9,
              ),
            )
          else
            _buildWindowsMockPlayer(),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsMockPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          widget.item.backdropUrl ?? widget.item.posterUrl ?? '',
          fit: BoxFit.cover,
          color: Colors.black54,
          colorBlendMode: BlendMode.darken,
          errorBuilder: (_, __, ___) => Container(color: Colors.black),
        ),
        Center(
          child: IconButton(
            iconSize: 64,
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            onPressed: () {},
          ),
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Row(
            children: [
              const Icon(Icons.play_arrow, color: Colors.white),
              const SizedBox(width: 8),
              const Text('0:00', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: 0.0,
                  onChanged: (val) {},
                ),
              ),
              const SizedBox(width: 8),
              const Text('2:30', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              const Icon(Icons.fullscreen, color: Colors.white),
            ],
          ),
        ),
      ],
    );
  }
}
