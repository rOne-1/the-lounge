import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/media_item.dart';
import 'fallback_widgets.dart';
import 'pressable_scale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/media_provider.dart';

class TrailerPlayer extends ConsumerStatefulWidget {
  final MediaItem item;

  const TrailerPlayer({super.key, required this.item});

  @override
  ConsumerState<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends ConsumerState<TrailerPlayer> {
  YoutubePlayerController? _controller;
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.item.hasTrailer &&
        (kIsWeb || defaultTargetPlatform == TargetPlatform.android)) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: 'dQw4w9WgXcQ', // Placeholder
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _showWindowsUnavailableFeedback() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Trailer playback isn't available on Windows yet."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDuration(double progress) {
    final totalSeconds = (progress * 150).round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    PressableScale(
                      onTap: () => Navigator.of(context).pop(),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: isYoutubePlatform && _controller != null
                ? Center(
                    child: YoutubePlayer(
                      controller: _controller!,
                      aspectRatio: 16 / 9,
                    ),
                  )
                : _buildWindowsMockPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsMockPlayer() {
    final imageUrl = widget.item.backdropUrl ?? widget.item.posterUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null && imageUrl.isNotEmpty && !widget.item.imageLoadWillFail)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            color: Colors.black54,
            colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          )
        else
          Container(color: Colors.black),
        Center(
          child: IconButton(
            iconSize: 64,
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            onPressed: _showWindowsUnavailableFeedback,
          ),
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                onPressed: _showWindowsUnavailableFeedback,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_sliderValue),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _sliderValue,
                  onChanged: (val) {
                    setState(() {
                      _sliderValue = val;
                    });
                  },
                  onChangeEnd: (_) => _showWindowsUnavailableFeedback(),
                ),
              ),
              const SizedBox(width: 8),
              const Text('2:30', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _showWindowsUnavailableFeedback,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
