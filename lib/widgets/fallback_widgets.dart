import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pressable_scale.dart';
import '../constants.dart';

export 'media_image.dart';

/// Helper function to detect socket/network exceptions and offline error messages.
bool isNetworkError(Object? error) {
  if (error == null) return false;
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException) {
    return true;
  }
  final s = error.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('failed host lookup') ||
      s.contains('no internet') ||
      s.contains('no connection') ||
      s.contains('network exception') ||
      s.contains('connection refused') ||
      s.contains('connection timed out') ||
      s.contains('network is unreachable') ||
      s.contains('host lookup failed');
}

/// Offline network widget stating "No connection — Please check your internet connection"
/// with a manual "Retry Connection" button.
class NoNetworkWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const NoNetworkWidget({
    super.key,
    this.message = 'No connection — Please check your internet connection',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final cardBg = context.ambianceColors.card;
    final borderColor = context.ambianceColors.lineRgba;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Connection',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: inkColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 24),
                PressableScale(
                  onTap: onRetry,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Connection'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FullScreenErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const FullScreenErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isNetworkError(message)) {
      return NoNetworkWidget(
        message: message.contains('No connection')
            ? message
            : 'No connection — Please check your internet connection',
        onRetry: onRetry,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InlinePartialErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const InlinePartialErrorWidget({
    super.key,
    this.message = 'Failed to load content',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaybackUnavailableWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onAddWatchlist;
  final VoidCallback? onWatchOnYouTube;

  const PlaybackUnavailableWidget({
    super.key,
    required this.title,
    this.message = 'This title is not available for playback right now.',
    required this.onAddWatchlist,
    this.onWatchOnYouTube,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          leading: PressableScale(
            onTap: () => Navigator.of(context).pop(),
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                if (onWatchOnYouTube != null) ...[
                  FilledButton.icon(
                    onPressed: onWatchOnYouTube,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Watch on YouTube'),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.tonalIcon(
                  onPressed: onAddWatchlist,
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Add to watchlist'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Blocking, app-root-level state for a release build with no valid TMDB
/// API token configured. Distinct from [FullScreenErrorWidget] — that widget
/// is for retryable network/data failures, but a missing embedded token
/// can't be fixed by retrying; it needs a fresh build with the token set.
/// See B6/D2 in the triage report: a release build must never silently fall
/// back to mock/placeholder content.
class ConfigurationErrorScreen extends StatelessWidget {
  const ConfigurationErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ambianceColors = context.ambianceColors;
    final errorColor = Theme.of(context).colorScheme.error;

    return Scaffold(
      backgroundColor: ambianceColors.base,
      body: Container(
        decoration: ambianceColors.background.copyWith(color: ambianceColors.base),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: AppPhysics.houseSpringDuration,
            curve: AppPhysics.houseSpringCurve,
            builder: (context, opacity, child) {
              return Opacity(opacity: opacity, child: child);
            },
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: ambianceColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: errorColor.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: errorColor.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_suggest_outlined,
                      size: 40,
                      color: errorColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CONFIGURATION REQUIRED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bodoniModa(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                      color: ambianceColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "This build is missing the connection it needs to load titles. "
                    "Please reinstall the latest release or contact support.",
                    textAlign: TextAlign.center,
                    style: AppThemes.safeGeist(
                      fontSize: 13,
                      color: ambianceColors.sub,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
