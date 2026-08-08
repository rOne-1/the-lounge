import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
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
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  Timer? _playbackTimeoutTimer;
  double _sliderValue = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.hasTrailer &&
        widget.item.trailerVideoId != null &&
        (kIsWeb || defaultTargetPlatform == TargetPlatform.android)) {
      _startPlaybackTimeoutTimer();
      try {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: widget.item.trailerVideoId!,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showControls: true,
            showFullscreenButton: true,
            playsInline: true,
            enableJavaScript: true,
            enableCaption: false,
            loop: false,
            strictRelatedVideos: true,
          ),
        );
        _playerSubscription = _controller!.listen((value) {
          if (value.hasError) {
            _playbackTimeoutTimer?.cancel();
            if (mounted && !_hasError) {
              setState(() {
                _hasError = true;
              });
            }
          } else if (value.playerState == PlayerState.playing) {
            _playbackTimeoutTimer?.cancel();
          }
        });
      } catch (_) {
        _playbackTimeoutTimer?.cancel();
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
          });
        }
      }
    }
  }

  void _startPlaybackTimeoutTimer() {
    _playbackTimeoutTimer?.cancel();
    _playbackTimeoutTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !_hasError) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _playbackTimeoutTimer?.cancel();
    _playerSubscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  Future<void> _launchYouTubeUrl(String videoId) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showUnavailableFeedback() {
    if (!mounted) return;
    final videoId = widget.item.trailerVideoId;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Trailer playback isn't available for this title"),
        action: videoId != null
            ? SnackBarAction(
                label: 'WATCH ON YOUTUBE',
                onPressed: () => _launchYouTubeUrl(videoId),
              )
            : null,
        duration: const Duration(seconds: 4),
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
    if (!widget.item.hasTrailer || widget.item.trailerVideoId == null || _hasError) {
      return PlaybackUnavailableWidget(
        title: widget.item.title,
        message: _hasError
            ? 'Playback unavailable in app'
            : 'This title is not available for playback right now.',
        onAddWatchlist: () {
          ref.read(mediaProvider.notifier).addToWatchlist(widget.item);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to Watchlist')),
          );
        },
        onWatchOnYouTube: widget.item.trailerVideoId != null
            ? () => _launchYouTubeUrl(widget.item.trailerVideoId!)
            : null,
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
    if (widget.item.trailerVideoId == null) {
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
            onPressed: _showUnavailableFeedback,
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
                onPressed: _showUnavailableFeedback,
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
                  onChangeEnd: (_) => _showUnavailableFeedback(),
                ),
              ),
              const SizedBox(width: 8),
              const Text('2:30', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _showUnavailableFeedback,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
