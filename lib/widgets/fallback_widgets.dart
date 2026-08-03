import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/media_item.dart';
import 'pressable_scale.dart';

class MediaPosterFallback extends StatelessWidget {
  final String title;
  final MediaType? type;
  final IconData? icon;
  final double? iconSize;
  final double? titleFontSize;
  final bool showTitle;

  const MediaPosterFallback({
    super.key,
    required this.title,
    this.type,
    this.icon,
    this.iconSize,
    this.titleFontSize,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.srAcc : AppColors.rrAcc;
    final textColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final cardBg = isDark ? AppColors.srCard : AppColors.rrCard;
    final borderColor = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    final resolvedIcon = icon ??
        (type == MediaType.tv ? Icons.tv_outlined : Icons.movie_outlined);

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final isVerySmall = height > 0 && height < 80;
          final effectiveIconSize = iconSize ?? (isVerySmall ? 18.0 : 26.0);
          final effectiveFontSize = titleFontSize ?? (isVerySmall ? 9.0 : 11.0);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: cardBg,
              border: Border.all(color: borderColor),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmall ? 4.0 : 8.0,
              vertical: isVerySmall ? 4.0 : 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  resolvedIcon,
                  color: iconColor.withValues(alpha: 0.85),
                  size: effectiveIconSize,
                ),
                if (showTitle && title.isNotEmpty) ...[
                  SizedBox(height: isVerySmall ? 2 : 5),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: isVerySmall ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.safeGeist(
                        fontSize: effectiveFontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class MediaImage extends StatelessWidget {
  final MediaItem? item;
  final String? imageUrl;
  final String title;
  final MediaType? type;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final bool showFallbackTitle;

  const MediaImage({
    super.key,
    this.item,
    this.imageUrl,
    this.title = '',
    this.type,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.showFallbackTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = imageUrl ?? item?.posterUrl;
    final effectiveTitle = item?.title ?? title;
    final effectiveType = item?.type ?? type;
    final willFail = item?.imageLoadWillFail ?? false;

    final fallbackWidget = fallback ??
        MediaPosterFallback(
          title: effectiveTitle,
          type: effectiveType,
          showTitle: showFallbackTitle,
        );

    Widget imageContent;
    if (effectiveUrl == null || effectiveUrl.isEmpty || willFail) {
      imageContent = fallbackWidget;
    } else {
      imageContent = Image.network(
        effectiveUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }
    return imageContent;
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

  const PlaybackUnavailableWidget({
    super.key,
    required this.title,
    this.message = 'This title is not available for playback right now.',
    required this.onAddWatchlist,
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
