import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ambient_glow.dart';
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

/// A luxury pill button shared by every fallback/error state: an icon,
/// a label, and either the theme's primary decoration or a flat fill.
class _LoungeFallbackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final BoxDecoration decoration;
  final Color foreground;

  const _LoungeFallbackButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.decoration,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppThemes.safeGeist(fontSize: 14, fontWeight: FontWeight.w600, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoungeFallbackCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<Widget> actions;

  const _LoungeFallbackCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final ambiance = context.ambianceColors;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AppPhysics.houseSpringDuration,
      curve: AppPhysics.houseSpringCurve,
      builder: (context, opacity, child) => Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: AmbientGlowWidget(
              enableAnimation: false, // static glow: error states should stay calm, not perpetually animate
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ambiance.lineRgba),
              boxShadow: [
                BoxShadow(
                  color: ambiance.surfaceHighlight,
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                  blurStyle: BlurStyle.inner,
                ),
              ],
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 52, color: iconColor),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bodoniModa(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: ambiance.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppThemes.safeGeist(fontSize: 13.5, height: 1.4, color: ambiance.sub),
                  ),
                  const SizedBox(height: 24),
                  Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 10, children: actions),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final ambiance = context.ambianceColors;
    return _LoungeFallbackCard(
      icon: Icons.wifi_off_rounded,
      iconColor: ambiance.danger,
      title: 'No Connection',
      message: message,
      actions: [
        _LoungeFallbackButton(
          icon: Icons.refresh_rounded,
          label: 'Retry Connection',
          onPressed: onRetry,
          decoration: ambiance.primaryButtonDecoration,
          foreground: Theme.of(context).colorScheme.onPrimary,
        ),
      ],
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
    final ambiance = context.ambianceColors;
    return _LoungeFallbackCard(
      icon: Icons.error_outline_rounded,
      iconColor: ambiance.danger,
      title: 'Something went wrong',
      message: message,
      actions: [
        _LoungeFallbackButton(
          icon: Icons.refresh_rounded,
          label: 'Try again',
          onPressed: onRetry,
          decoration: ambiance.primaryButtonDecoration,
          foreground: Theme.of(context).colorScheme.onPrimary,
        ),
      ],
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
    final ambiance = context.ambianceColors;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: AppPhysics.houseSpringDuration,
      curve: AppPhysics.houseSpringCurve,
      builder: (context, opacity, child) => Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
      child: AmbientGlowWidget(
              enableAnimation: false, // static glow: error states should stay calm, not perpetually animate
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ambiance.danger.withValues(alpha: 0.35)),
        baseColor: ambiance.danger.withValues(alpha: 0.10),
        color1: ambiance.danger,
        color2: ambiance.danger,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ambiance.danger, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppThemes.safeGeist(fontSize: 13, color: ambiance.ink),
              ),
            ),
            PressableScale(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w700, color: ambiance.danger),
              ),
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
    final ambiance = context.ambianceColors;
    return Scaffold(
      backgroundColor: ambiance.base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: PressableScale(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.close, color: ambiance.ink),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        builder: (context, opacity, child) => Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_off_rounded, size: 72, color: ambiance.sub),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.bodoniModa(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: ambiance.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppThemes.safeGeist(fontSize: 14, height: 1.4, color: ambiance.sub),
                ),
                const SizedBox(height: 32),
                if (onWatchOnYouTube != null) ...[
                  // YouTube's own brand red -- a third-party mark, not an
                  // app theme color, deliberately left un-retinted.
                  _LoungeFallbackButton(
                    icon: Icons.open_in_new_rounded,
                    label: 'Watch on YouTube',
                    onPressed: onWatchOnYouTube,
                    decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(999)),
                    foreground: Colors.white,
                  ),
                  const SizedBox(height: 12),
                ],
                _LoungeFallbackButton(
                  icon: Icons.bookmark_add_rounded,
                  label: 'Add to watchlist',
                  onPressed: onAddWatchlist,
                  decoration: ambiance.primaryButtonDecoration,
                  foreground: Theme.of(context).colorScheme.onPrimary,
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
              return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
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
