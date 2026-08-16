import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants.dart';
import '../models/media_item.dart';


/// Fallback widget displayed when poster image fails to load or path is empty.
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
    final iconColor = context.ambianceColors.acc;
    final textColor = context.ambianceColors.ink;
    final cardBg = context.ambianceColors.card;
    final borderColor = context.ambianceColors.lineRgba;

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

/// Context-aware image component with fallback handling.
class MediaImage extends StatelessWidget {
  final MediaItem? item;
  final String? imageUrl;
  final String title;
  final MediaType? type;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;
  final bool showFallbackTitle;
  final bool useDetailPoster;
  final int? memCacheWidth;
  final int? memCacheHeight;

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
    this.useDetailPoster = false,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = imageUrl ??
        (useDetailPoster ? item?.effectiveDetailPosterUrl : item?.posterUrl);
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
      // B4/B11: decode at the card's actual on-screen physical size (logical
      // constraints x devicePixelRatio), not a single blanket default. A
      // fixed 200 was too small for large cards on high-DPI screens (soft
      // images, B11) and too large for small cards (wasted decode work
      // scaling with rail length, B4). Falls back to the previous
      // fixed defaults only when a parent gives unbounded constraints
      // (LayoutBuilder can't size from those) or a caller explicitly
      // overrides via memCacheWidth/memCacheHeight (e.g. a hero banner with
      // a deliberately fixed size).
      imageContent = LayoutBuilder(
        builder: (context, constraints) {
          final dpr = MediaQuery.of(context).devicePixelRatio;

          int? resolvedWidth;
          int? resolvedHeight;
          if (memCacheWidth != null || memCacheHeight != null) {
            // Caller explicitly overrode one or both dimensions (e.g. a
            // hero banner with a deliberately fixed size) -- respect that
            // as given.
            resolvedWidth = memCacheWidth;
            resolvedHeight = memCacheHeight;
          } else if (constraints.hasBoundedWidth) {
            // IMAGE-1: only ever derive ONE dimension from the box
            // constraints, not both. Passing both memCacheWidth and
            // memCacheHeight tells CachedNetworkImage's underlying
            // ResizeImage to force-decode into that exact W x H box
            // regardless of the source image's real aspect ratio --
            // fine for posters (2:3, matches most card shapes) but it
            // squished portrait cast photos into whatever square/non-2:3
            // box their container happened to have (e.g. circular
            // avatars). Deriving width only lets the decoder preserve
            // the source aspect ratio and BoxFit handle the crop.
            resolvedWidth = (constraints.maxWidth * dpr).round();
          } else if (constraints.hasBoundedHeight) {
            resolvedHeight = (constraints.maxHeight * dpr).round();
          } else {
            resolvedWidth = useDetailPoster ? 700 : 200;
          }

          return CachedNetworkImage(
            imageUrl: effectiveUrl,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: resolvedWidth,
            memCacheHeight: resolvedHeight,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (context, url) => Container(
              color: context.ambianceColors.ph,
            ),
            errorWidget: (context, url, error) => fallbackWidget,
          );
        },
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
