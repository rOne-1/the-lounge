import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../models/media_item.dart';
import '../screens/detail_screen.dart';
import 'media_image.dart';
import 'quick_status_sheet.dart';

/// Reusable media card component with long-press quick-save support.
class MediaCard extends ConsumerWidget {
  final MediaItem item;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isDark;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showTitle;
  final bool showSubtitle;
  final String? customSubtitle;
  final Widget? badge;
  final BoxFit fit;

  const MediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.borderRadius = 11.0,
    required this.isDark,
    this.onTap,
    this.onLongPress,
    this.showTitle = false,
    this.showSubtitle = false,
    this.customSubtitle,
    this.badge,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subColor = context.ambianceColors.sub;
    final inkColor = context.ambianceColors.ink;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;

    final posterWidget = OpenContainer(
      transitionDuration: AppPhysics.houseSpringDuration,
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: context.ambianceColors.base,
      middleColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      closedBuilder: (context, openContainer) {
        return GestureDetector(
          onTap: onTap ?? openContainer,
          onLongPress: onLongPress ?? () => showQuickStatusSheet(context, ref, item),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: phColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: lineRgba),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color.fromRGBO(255, 255, 255, 0.05)
                      : const Color.fromRGBO(255, 255, 255, 0.4),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                  blurStyle: BlurStyle.inner,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaImage(
                  item: item,
                  fit: fit,
                ),
                if (badge != null) badge!,
              ],
            ),
          ),
        );
      },
      openBuilder: (context, _) => DetailScreen(id: item.prefixedId),
    );

    if (!showTitle && !showSubtitle) {
      return posterWidget;
    }

    final subtitleText = customSubtitle ??
        (item.genres.isNotEmpty
            ? item.genres.first
            : (item.type == MediaType.movie ? 'Movie' : 'TV Show'));

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          posterWidget,
          if (showTitle) ...[
            const SizedBox(height: 6),
            Text(
              item.title,
              style: AppThemes.safeGeist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: inkColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (showSubtitle) ...[
            const SizedBox(height: 2),
            Text(
              subtitleText,
              style: AppThemes.safeGeist(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: subColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
