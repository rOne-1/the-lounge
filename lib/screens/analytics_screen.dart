import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';
import '../providers/analytics_provider.dart';
import '../utils/relative_time.dart';
import '../widgets/analytics/binge_velocity_section.dart';
import '../widgets/analytics/chronological_heatmap.dart';
import '../widgets/archive_summary_card.dart';
import '../widgets/atmospheric_empty_state.dart';
import '../widgets/pressable_scale.dart';

/// ANLY-HUB-2: the Analytics epic's hub screen. Follows the Archive/Tools
/// scaffolding convention exactly (custom top-bar, not a stock AppBar;
/// SingleChildScrollView + 720px-constrained content; `isLarge` driving
/// only horizontal padding).
///
/// Three states, gated entirely by [AnalyticsState] (never computed as a
/// side effect of opening this screen -- SP-1):
/// - idle: no result yet -> a ceremonial [AtmosphericEmptyState] with an
///   explicit "Generate Analytics" button. Nothing computes before this tap.
/// - loading: `isGenerating` -> the app's established full-screen loading
///   treatment (plain centered CircularProgressIndicator, matching every
///   other async-load screen in the app -- Discover, Calendar, Search).
/// - results: sectioned metric groups (Temporal built out first; Taste and
///   Share land in later phases of the epic and are appended here as they
///   ship, not stubbed as "coming soon" placeholders -- a screen only ever
///   shows shipped, fully-polished sections, per SP-2).
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.ambianceColors;
    final isLarge = MediaQuery.of(context).size.width >= 600;
    final paddingHorizontal = isLarge ? 24.0 : 18.0;
    final state = ref.watch(analyticsProvider);

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
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  if (state.isGenerating)
                    const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.result == null)
                    _buildIdleState(context, ref)
                  else
                    _AnalyticsResults(state: state, ref: ref),
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
                  color: colors.scrim.withValues(alpha: colors.isDark ? 0.25 : 0.06),
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
                'Analytics',
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
                'On-device insights from your own watch history',
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

  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: AtmosphericEmptyState(
        icon: Icons.insights_rounded,
        title: 'Ready when you are',
        message: 'Generate a fresh look at your watching habits -- computed '
            'entirely on this device, only when you ask for it.',
        ctaLabel: 'Generate Analytics',
        onCta: () => ref.read(analyticsProvider.notifier).generate(),
      ),
    );
  }
}

class _AnalyticsResults extends StatelessWidget {
  final AnalyticsState state;
  final WidgetRef ref;

  const _AnalyticsResults({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    final result = state.result!;
    final movieHours = (result.timeInvestment.movieMinutes / 60).round();
    final tvHours = (result.timeInvestment.tvMinutes / 60).round();

    return TweenAnimationBuilder<double>(
      key: ValueKey(state.generatedAt),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppPhysics.houseSpringDuration,
      curve: AppPhysics.houseSpringCurve,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t.clamp(0.0, 1.0)) * 16),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  state.generatedAt != null
                      ? 'Updated ${formatRelativeTime(state.generatedAt!)}'
                      : '',
                  style: AppThemes.safeGeist(fontSize: 12.5, color: colors.sub),
                ),
              ),
              PressableScale(
                onTap: () => ref.read(analyticsProvider.notifier).generate(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.pill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.lineRgba),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: colors.ink),
                      const SizedBox(width: 6),
                      Text(
                        'Regenerate',
                        style: AppThemes.safeGeist(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Temporal'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.16,
            children: [
              ArchiveSummaryCard(
                label: 'Movies',
                subtitle: movieHours == 1 ? '1 hour watched' : '$movieHours hours watched',
                count: movieHours,
                icon: Icons.local_movies_rounded,
                statusColor: colors.acc,
                onTap: () {},
              ),
              ArchiveSummaryCard(
                label: 'TV Shows',
                subtitle: tvHours == 1
                    ? '~1 hour watched (estimate)'
                    : '~$tvHours hours watched (estimate)',
                count: tvHours,
                icon: Icons.live_tv_rounded,
                statusColor: colors.acc,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Watch Activity',
            style: AppThemes.safeGeist(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.sub,
            ),
          ),
          const SizedBox(height: 10),
          ChronologicalHeatmap(data: result.heatmap),
          const SizedBox(height: 20),
          BingeVelocitySection(data: result.bingeVelocity),
        ],
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;
    return Text(
      title,
      style: GoogleFonts.bodoniModa(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: colors.ink,
      ),
    );
  }
}
