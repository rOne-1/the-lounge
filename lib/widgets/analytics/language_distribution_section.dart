import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../utils/analytics_engine.dart';

/// EXP-GLOBAL-1: breakdown of watched titles by original spoken language.
/// Country-of-production is deliberately out of scope for this pass (see
/// the expansion triage doc's EXP-GLOBAL-2 judgment call) -- this reflects
/// language only.
class LanguageDistributionSection extends StatelessWidget {
  final LanguageDistribution languages;

  const LanguageDistributionSection({super.key, required this.languages});

  static const Map<String, String> _displayNames = {
    'en': 'English',
    'ja': 'Japanese',
    'fr': 'French',
    'es': 'Spanish',
    'ko': 'Korean',
    'zh': 'Mandarin',
    'de': 'German',
    'it': 'Italian',
    'hi': 'Hindi',
    'ru': 'Russian',
    'pt': 'Portuguese',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'th': 'Thai',
    'tr': 'Turkish',
    'pl': 'Polish',
    'nl': 'Dutch',
    'ar': 'Arabic',
    'cn': 'Cantonese',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.ambianceColors;

    if (languages.counts.isEmpty) {
      return Text(
        'Watch a few more titles to see your language breadth.',
        style: AppThemes.safeGeist(fontSize: 13, color: colors.sub),
      );
    }

    final total = languages.counts.values.reduce((a, b) => a + b);
    final sorted = languages.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayNames[entry.key] ?? entry.key.toUpperCase(),
                    style: AppThemes.safeGeist(fontSize: 13, color: colors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${((entry.value / total) * 100).round()}%',
                  style: AppThemes.safeGeist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.sub,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.acc.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${entry.value}',
                    style: AppThemes.safeGeist(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: colors.acc,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
