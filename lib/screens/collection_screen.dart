import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants.dart';
import '../models/media_collection_detail.dart';
import '../providers/repository_provider.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/quick_status_sheet.dart';
import 'detail_screen.dart';

final collectionDetailsProvider =
    FutureProvider.family<MediaCollectionDetail?, int>((ref, collectionId) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getCollectionDetails(collectionId);
});

class CollectionScreen extends ConsumerWidget {
  final int collectionId;

  const CollectionScreen({
    super.key,
    required this.collectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.ambianceColors.isDark;

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final phColor = context.ambianceColors.ph;
    final lineRgba = context.ambianceColors.lineRgba;
    final bgColor = context.ambianceColors.base;
    final accColor = context.ambianceColors.acc;

    final collectionAsync = ref.watch(collectionDetailsProvider(collectionId));

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 5 : (width > 600 ? 4 : 3);

    return Scaffold(
      backgroundColor: bgColor,
      body: collectionAsync.when(
        data: (collection) {
          if (collection == null) {
            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: BackButton(color: inkColor),
              ),
              body: Center(
                child: Text(
                  'Collection not found.',
                  style: AppThemes.safeGeist(color: subColor, fontSize: 14),
                ),
              ),
            );
          }

          final imageUrl = collection.backdropUrl ?? collection.posterUrl;

          return CustomScrollView(
            slivers: [
              // SliverAppBar with backdrop banner
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: bgColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: PressableScale(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color.fromRGBO(0, 0, 0, 0.6)
                            : const Color.fromRGBO(255, 255, 255, 0.8),
                      ),
                      child: Icon(Icons.arrow_back, color: inkColor, size: 20),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    collection.name,
                    style: GoogleFonts.bodoniModa(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: phColor),
                        )
                      else
                        Container(color: phColor),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              bgColor.withAlpha(100),
                              bgColor,
                            ],
                            stops: const [0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Overview Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accColor.withAlpha(100)),
                            ),
                            child: Text(
                              'FRANCHISE COLLECTION',
                              style: AppThemes.safeGeist(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: accColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${collection.parts.length} Titles',
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                      if (collection.overview != null && collection.overview!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          collection.overview!,
                          style: AppThemes.safeGeist(
                            fontSize: 14,
                            height: 1.45,
                            color: inkColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Collection Titles',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: inkColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Responsive Grid of Collection Titles
              if (collection.parts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No titles listed in this collection.',
                        style: AppThemes.safeGeist(color: subColor, fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    24.0 + MediaQuery.of(context).padding.bottom,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = collection.parts[index];
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
                                onLongPress: () => showQuickStatusSheet(context, ref, item),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: phColor,
                                    border: Border.all(color: lineRgba),
                                    borderRadius: BorderRadius.circular(12),
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
                                              color: context.ambianceColors.scrim,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.star,
                                                    size: 10, color: context.ambianceColors.starRating),
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
                      childCount: collection.parts.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(color: inkColor),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(color: inkColor),
          ),
          body: FullScreenErrorWidget(
            message: err.toString().replaceAll('Exception: ', ''),
            onRetry: () => ref.refresh(collectionDetailsProvider(collectionId)),
          ),
        ),
      ),
    );
  }
}
