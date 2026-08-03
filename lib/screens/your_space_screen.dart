import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/media_provider.dart';
import '../models/media_item.dart';
import 'detail_screen.dart';
import '../constants.dart';
import '../widgets/fallback_widgets.dart';
import '../widgets/pressable_scale.dart';

class YourSpaceScreen extends ConsumerWidget {
  const YourSpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final subColor = isDark ? AppColors.srSub : AppColors.rrSub;
    final accColor = isDark ? AppColors.srAcc : AppColors.rrAcc;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: accColor,
            unselectedLabelColor: subColor,
            indicatorColor: accColor,
            labelStyle: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppThemes.safeGeist(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Watchlist'),
              Tab(text: 'Maybe'),
              Tab(text: 'Watched'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGrid(context, mediaState.watchlist.values.toList(), isDark, subColor),
                _buildGrid(context, mediaState.maybeList.values.toList(), isDark, subColor),
                _buildGrid(context, mediaState.watchedList.values.toList(), isDark, subColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<MediaItem> items, bool isDark, Color subColor) {
    if (items.isEmpty) {
      return Center(child: Text('Nothing here yet.', style: AppThemes.safeGeist(fontSize: 14, color: subColor)));
    }
    
    final phColor = isDark ? AppColors.srPh : AppColors.rrPh;
    final lineRgba = isDark ? AppColors.srLineRgba : AppColors.rrLineRgba;

    return GridView.builder(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18.0 + MediaQuery.of(context).padding.bottom),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return PressableScale(
          child: OpenContainer(
            transitionDuration: const Duration(milliseconds: 300),
            closedElevation: 0,
            openElevation: 0,
            closedColor: Colors.transparent,
            openColor: isDark ? AppColors.srBase : AppColors.rrBase,
            middleColor: Colors.transparent,
            closedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            closedBuilder: (context, openContainer) {
              return GestureDetector(
                onTap: openContainer,
                child: Container(
                  decoration: BoxDecoration(
                    color: phColor,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: lineRgba),
                    boxShadow: [
                      BoxShadow(color: isDark ? const Color.fromRGBO(255, 255, 255, 0.05) : const Color.fromRGBO(255, 255, 255, 0.4), blurRadius: 0, spreadRadius: 0, offset: const Offset(0, 1), blurStyle: BlurStyle.inner)
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaImage(
                    item: item,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
            openBuilder: (context, _) => DetailScreen(id: item.id),
          ),
        ).animate().fade(duration: 250.ms).slideY(
            begin: 0.1,
            end: 0,
            delay: (index.clamp(0, 5) * 40).ms);
      },
    );
  }
}
