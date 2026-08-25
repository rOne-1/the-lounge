import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants.dart';
import '../models/media_collection_detail.dart';
import '../providers/media_provider.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/media_card.dart';
import '../widgets/pressable_scale.dart';

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
            // COLL-REG-1: getCollectionDetails swallows any failure --
            // network hiccup, TMDB rate limit, transient parse error --
            // into a null return rather than throwing, so this branch
            // covers both "genuinely no such collection" and "the one
            // request that ever ran for this id happened to fail." A
            // plain (non-autoDispose) FutureProvider.family never
            // re-fetches on its own once it has a cached null result, so
            // without a retry action here a transient failure permanently
            // "collection not found"s this id for the rest of the app
            // session -- matching the reported regression ("used to work,
            // now doesn't") far better than an actually-deleted TMDB
            // collection would.
            return Scaffold(
              backgroundColor: bgColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: BackButton(color: inkColor),
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Collection not found.',
                      style: AppThemes.safeGeist(color: subColor, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    PressableScale(
                      onTap: () =>
                          ref.refresh(collectionDetailsProvider(collectionId)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: accColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: accColor),
                        ),
                        child: Text(
                          'Retry',
                          style: AppThemes.safeGeist(
                            color: accColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final imageUrl = collection.backdropUrl ?? collection.posterUrl;

          // DATA-FRAN-2: computed locally from the collection detail this
          // screen already fetched (no extra network call) cross-referenced
          // against the Watched shelf -- "3 of 8 Watched (37%)" instead of
          // a raw part count.
          final watchedList = ref.watch(mediaProvider).watchedList;
          final totalCount = collection.parts.length;
          final watchedCount = collection.parts
              .where((p) => watchedList.containsKey(p.prefixedId))
              .length;
          final completionPct =
              totalCount > 0 ? ((watchedCount / totalCount) * 100).round() : 0;

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
                    style: AppThemes.display(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                            totalCount > 0
                                ? '$watchedCount of $totalCount Watched ($completionPct%)'
                                : '0 Titles',
                            style: AppThemes.safeGeist(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            height: 5,
                            child: Stack(
                              children: [
                                Container(color: context.ambianceColors.lineRgba),
                                FractionallySizedBox(
                                  widthFactor:
                                      (watchedCount / totalCount).clamp(0.0, 1.0),
                                  child: Container(color: accColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                        style: AppThemes.display(
                          context,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
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
                        return MediaCard(
                          key: ValueKey(item.prefixedId),
                          item: item,
                          isDark: isDark,
                          borderRadius: 12,
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
