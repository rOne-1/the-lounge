import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/media_item.dart';
import 'fallback_widgets.dart';
import 'lounge_slider.dart';
import 'lounge_toast.dart';
import 'pressable_scale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/media_provider.dart';

/// A frosted-glass circular icon button for the trailer player's overlay
/// chrome. The player stays black/white cinema chrome regardless of app
/// ambiance (matching real-world video player convention), but the frosted
/// glass + PressableScale physics keep it feeling native to the app.
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final VoidCallback? onPressed;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      // B4: RepaintBoundary isolates this into its own compositing layer --
      // BackdropFilter composited underneath PressableScale's own press
      // AnimatedScale can otherwise render fully black and stay that way
      // until something forces a full scene recomposite.
      child: RepaintBoundary(
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}

class TrailerPlayer extends ConsumerStatefulWidget {
  final MediaItem item;
  final String? videoId;
  final String? videoTitle;

  const TrailerPlayer({
    super.key,
    required this.item,
    this.videoId,
    this.videoTitle,
  });

  @override
  ConsumerState<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends ConsumerState<TrailerPlayer> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  Timer? _playbackTimeoutTimer;
  double _sliderValue = 0.0;
  bool _hasError = false;

  String? get _effectiveVideoId => widget.videoId ?? widget.item.trailerVideoId;
  String get _effectiveTitle => widget.videoTitle ?? widget.item.title;

  @override
  void initState() {
    super.initState();
    final videoId = _effectiveVideoId;
    final hasTrailer = widget.item.hasTrailer || widget.videoId != null;

    if (hasTrailer && videoId != null && videoId.isNotEmpty) {
      _startPlaybackTimeoutTimer();
      if (kIsWeb) {
        try {
          _controller = YoutubePlayerController.fromVideoId(
            videoId: videoId,
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
    final videoId = _effectiveVideoId;
    LoungeToast.show(
      context,
      "Trailer playback isn't available for this title",
      duration: const Duration(seconds: 4),
      actionLabel:
          videoId != null && videoId.isNotEmpty ? 'WATCH ON YOUTUBE' : null,
      onAction: videoId != null && videoId.isNotEmpty
          ? () => _launchYouTubeUrl(videoId)
          : null,
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
    final videoId = _effectiveVideoId;
    final hasTrailer = widget.item.hasTrailer || widget.videoId != null;
    if (!hasTrailer || videoId == null || videoId.isEmpty || _hasError) {
      return PlaybackUnavailableWidget(
        title: _effectiveTitle,
        message: _hasError
            ? 'Playback unavailable in app'
            : 'This title is not available for playback right now.',
        onAddWatchlist: () {
          ref.read(mediaProvider.notifier).addToWatchlist(widget.item);
          LoungeToast.show(context, 'Added to Watchlist',
              type: ToastType.success);
        },
        onWatchOnYouTube: videoId != null && videoId.isNotEmpty
            ? () => _launchYouTubeUrl(videoId)
            : null,
      );
    }

    final isYoutubePlatform = kIsWeb;

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
                    _GlassIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _effectiveTitle,
                        style: GoogleFonts.bodoniModa(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
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
    final videoId = _effectiveVideoId;
    if (videoId == null || videoId.isEmpty) {
      return PlaybackUnavailableWidget(
        title: _effectiveTitle,
        onAddWatchlist: () {
          ref.read(mediaProvider.notifier).addToWatchlist(widget.item);
          LoungeToast.show(context, 'Added to Watchlist',
              type: ToastType.success);
        },
      );
    }
    final imageUrl = widget.item.backdropUrl ?? widget.item.posterUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null &&
            imageUrl.isNotEmpty &&
            !widget.item.imageLoadWillFail)
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
          child: _GlassIconButton(
            icon: Icons.play_circle_fill,
            size: 72,
            iconSize: 40,
            onPressed: _showUnavailableFeedback,
          ),
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Row(
            children: [
              _GlassIconButton(
                icon: Icons.play_arrow,
                onPressed: _showUnavailableFeedback,
              ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_sliderValue),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LoungeSlider(
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
              const Text('2:30',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(width: 10),
              _GlassIconButton(
                icon: Icons.fullscreen,
                onPressed: _showUnavailableFeedback,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
