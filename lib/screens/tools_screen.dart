import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../widgets/pressable_scale.dart';
import 'cleanup_swipe_screen.dart';
import 'folders_screen.dart';
import 'rate_titles_screen.dart';
import 'rewatch_vault_screen.dart';

/// YSR-HUB-2: The Tools Hub (`tools.png`) - a dedicated 2x2 curation tools
/// matrix providing access to batch rating, custom folders, cleanup swipe,
/// and the rewatch vault. Features luxury gradients, squircle icon badges,
/// and surface highlights matching the Screening Room design system.
/// Fully responsive and width-constrained for multi-device harmony.
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;

    return Scaffold(
      backgroundColor: colors.base,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            paddingHorizontal,
            14.0,
            paddingHorizontal,
            100.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar with Back Button & Header
                  _buildTopBar(context),
                  const SizedBox(height: 24),

                  // 2x2 Tools Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.15,
                    children: [
                      _ToolCard(
                        icon: Icons.star_rounded,
                        title: 'Rate Titles',
                        subtitle: 'Batch rating tool',
                        onTap: () => _push(context, const RateTitlesScreen()),
                      ),
                      _ToolCard(
                        icon: Icons.folder_rounded,
                        title: 'Custom Folders',
                        subtitle: 'Curated playlists',
                        onTap: () => _push(context, const FoldersScreen()),
                      ),
                      _ToolCard(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Cleanup Session',
                        subtitle: 'Tidy up Saved',
                        onTap: () => _push(context, const CleanupSwipeScreen()),
                      ),
                      _ToolCard(
                        icon: Icons.replay_rounded,
                        title: 'Rewatch Vault',
                        subtitle: 'Titles you\'ve rewatched',
                        onTap: () => _push(context, const RewatchVaultScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.ambianceColors;

    return Row(
      children: [
        PressableScale(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: colors.lineRgba),
              boxShadow: [
                BoxShadow(
                  color: colors.isDark
                      ? const Color(0x18000000)
                      : const Color(0x06000000),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: colors.ink,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tools',
                style: GoogleFonts.bodoniModa(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: colors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Keep your space in order',
                style: AppThemes.safeGeist(
                  fontSize: 13.5,
                  color: colors.sub,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final accent = colors.acc;
    final isDark = colors.isDark;

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.28 : 0.35),
            width: 1.2,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    accent.withValues(alpha: 0.12),
                    colors.card,
                  ]
                : [
                    accent.withValues(alpha: 0.08),
                    colors.card,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.08 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            if (isDark)
              BoxShadow(
                color: colors.surfaceHighlight,
                blurRadius: 0,
                offset: const Offset(0, 1),
                blurStyle: BlurStyle.inner,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.14),
                borderRadius: BorderRadius.circular(11.0),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: AppThemes.safeGeist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: AppThemes.safeGeist(
                      fontSize: 12.5,
                      color: colors.sub,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
