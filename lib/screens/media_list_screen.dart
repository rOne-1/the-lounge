import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../constants.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import 'detail_screen.dart';

typedef RailFullListScreen = MediaListScreen;

class MediaListScreen extends ConsumerWidget {
  final String title;
  final FutureProvider<List<MediaItem>> itemsProvider;

  const MediaListScreen({
    super.key,
    required this.title,
    required this.itemsProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inkColor = isDark ? AppColors.srInk : AppColors.rrInk;
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;
    final bgColor = isDark ? AppColors.srBase : AppColors.rrBase;

    final itemsAsync = ref.watch(itemsProvider);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 5 : (width > 600 ? 4 : 3);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox.expand(
      child: DecoratedBox(
        decoration: isDark
            ? AppThemes.screeningRoomBackground()
            : AppThemes.readingRoomBackground(),
        child: Scaffold(
          backgroundColor: bgColor,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: isDark
                      ? AppColors.srBase.withAlpha(191)
                      : AppColors.rrBase.withAlpha(191),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    leading: Center(
                      child: PressableScale(
                        onTap: () => Navigator.maybePop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.srPill : AppColors.rrPill,
                          ),
                          child: Icon(Icons.arrow_back, color: inkColor, size: 18),
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      style: GoogleFonts.bodoniModa(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: inkColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: itemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No items found.',
                    style: AppThemes.safeGeist(
                      fontSize: 14,
                      color: subColor,
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 68,
                  16,
                  16 + bottomPadding,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return PressableScale(
                    child: OpenContainer(
                      transitionDuration: AppPhysics.houseSpringDuration,
                      closedElevation: 0,
                      openElevation: 0,
                      closedColor: Colors.transparent,
                      openColor: bgColor,
                      middleColor: Colors.transparent,
                      closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      closedBuilder: (context, openContainer) {
                        return GestureDetector(
                          onTap: openContainer,
                          child: Container(
                            decoration: BoxDecoration(
                              color: phColor,
                              border: Border.all(color: lineRgba),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? const Color.fromRGBO(255, 255, 255, 0.05)
                                      : const Color.fromRGBO(255, 255, 255, 0.5),
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
                                  fit: BoxFit.cover,
                                ),
                                if (item.rating > 0)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color.fromRGBO(0, 0, 0, 0.65)
                                            : const Color.fromRGBO(44, 32, 22, 0.75),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star,
                                              size: 10, color: Color(0xFFFFB800)),
                                          const SizedBox(width: 3),
                                          Text(
                                            item.rating.toStringAsFixed(1),
                                            style: AppThemes.safeGeist(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      openBuilder: (context, _) =>
                          DetailScreen(id: item.prefixedId),
                    ),
                  ).animate().fade(duration: 250.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        delay: (index.clamp(0, 8) * 30).ms,
                      );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) {
              final message = err.toString().replaceAll('Exception: ', '');
              return FullScreenErrorWidget(
                message: message.isNotEmpty
                    ? message
                    : 'Failed to load media list.',
                onRetry: () => ref.invalidate(itemsProvider),
              );
            },
          ),
        ),
      ),
    );
  }
}
