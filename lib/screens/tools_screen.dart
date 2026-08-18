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
/// and the rewatch vault.
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
            16.0,
            paddingHorizontal,
            100.0 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back Button & Header
              _buildTopBar(context),
              const SizedBox(height: 28),

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
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.ink,
              size: 16,
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
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: colors.ink,
                  letterSpacing: -0.3,
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

    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPhysics.houseSpringDuration,
        curve: AppPhysics.houseSpringCurve,
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(22.0),
          border: Border.all(
            color: accent.withValues(alpha: 0.24),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.isDark
                  ? const Color(0x22000000)
                  : const Color(0x0A000000),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                color: accent,
                size: 21,
              ),
            ),
            const SizedBox(height: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppThemes.safeGeist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    color: colors.sub,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
