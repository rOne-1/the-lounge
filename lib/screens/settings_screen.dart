import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/media_provider.dart';
import '../providers/ambiance_provider.dart';
import '../constants.dart';
import '../utils/export_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambiance = ref.watch(ambianceProvider);
    final isDark = context.ambianceColors.isDark;
    final mediaState = ref.watch(mediaProvider);

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final accColor = context.ambianceColors.acc;
    final cardBg = context.ambianceColors.card;

    final bgDeco = context.ambianceColors.background;

    return Scaffold(
      body: Container(
        decoration: bgDeco,
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: inkColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Settings',
                      style: GoogleFonts.bodoniModa(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: inkColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  children: [
                    // Section 1: Ambiance
                    _buildSectionHeader('Ambiance', subColor),
                    _buildCard(context, 
                      cardBg,
                      isDark,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Theme',
                              style: AppThemes.safeGeist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: inkColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<AmbianceType>(
                              segments: const [
                                ButtonSegment(
                                  value: AmbianceType.readingRoom,
                                  label: Text('Reading'),
                                ),
                                ButtonSegment(
                                  value: AmbianceType.screeningRoom,
                                  label: Text('Screening'),
                                ),
                                ButtonSegment(
                                  value: AmbianceType.violetDusk,
                                  label: Text('Violet'),
                                ),
                              ],
                              selected: {ambiance},
                              onSelectionChanged: (Set<AmbianceType> newSelection) {
                                ref.read(ambianceProvider.notifier).setAmbiance(newSelection.first);
                              },
                              style: SegmentedButton.styleFrom(
                                foregroundColor: subColor,
                                selectedForegroundColor: context.ambianceColors.base,
                                selectedBackgroundColor: accColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Data Management
                    _buildSectionHeader('Data Management', subColor),
                    _buildCard(context, 
                      cardBg,
                      isDark,
                      child: Column(
                        children: [
                          ListTile(
                            key: const ValueKey('export_backup_button'),
                            leading: Icon(Icons.download, color: accColor),
                            title: Text(
                              'Export Backup',
                              style: AppThemes.safeGeist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: inkColor,
                              ),
                            ),
                            subtitle: Text(
                              'Save your current space to a JSON file',
                              style: AppThemes.safeGeist(fontSize: 12, color: subColor),
                            ),
                            onTap: () async {
                              final jsonString = ref.read(mediaProvider.notifier).exportBackupJson(ambiance.name);
                              try {
                                await saveJsonFile(jsonString, 'the_lounge_backup.json');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Backup exported successfully.', style: AppThemes.safeGeist(color: Colors.white)),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Export failed: $e', style: AppThemes.safeGeist(color: Colors.white)),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          Divider(color: context.ambianceColors.lineRgba, height: 1),
                          ListTile(
                            key: const ValueKey('share_backup_button'),
                            leading: Icon(Icons.share, color: accColor),
                            title: Text(
                              'Share Backup',
                              style: AppThemes.safeGeist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: inkColor,
                              ),
                            ),
                            subtitle: Text(
                              'Share your space data file directly',
                              style: AppThemes.safeGeist(fontSize: 12, color: subColor),
                            ),
                            onTap: () async {
                              final jsonString = ref.read(mediaProvider.notifier).exportBackupJson(ambiance.name);
                              try {
                                await shareJsonFile(jsonString, 'the_lounge_backup.json');
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Share failed: $e', style: AppThemes.safeGeist(color: Colors.white)),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          Divider(color: context.ambianceColors.lineRgba, height: 1),
                          ListTile(
                            key: const ValueKey('import_backup_button'),
                            leading: Icon(Icons.upload, color: accColor),
                            title: Text(
                              'Import Backup',
                              style: AppThemes.safeGeist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: inkColor,
                              ),
                            ),
                            subtitle: Text(
                              'Restore your space from a JSON file',
                              style: AppThemes.safeGeist(fontSize: 12, color: subColor),
                            ),
                            onTap: () async {
                              try {
                                final jsonString = await pickJsonFile();
                                if (jsonString == null || jsonString.isEmpty) {
                                  return; // User cancelled
                                }

                                final hasLocalData = mediaState.watchlist.isNotEmpty ||
                                    mediaState.maybeList.isNotEmpty ||
                                    mediaState.watchingList.isNotEmpty ||
                                    mediaState.watchedList.isNotEmpty ||
                                    mediaState.droppedList.isNotEmpty ||
                                    mediaState.onHoldList.isNotEmpty ||
                                    mediaState.watchedEpisodes.isNotEmpty;

                                bool shouldImport = true;
                                if (hasLocalData && context.mounted) {
                                  shouldImport = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: cardBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: context.ambianceColors.lineRgba,
                                        ),
                                      ),
                                      title: Text(
                                        'Overwrite current data?',
                                        style: AppThemes.safeGeist(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: inkColor,
                                        ),
                                      ),
                                      content: Text(
                                        'This will replace all your current watchlists, watch history, and settings. Are you sure you want to overwrite?',
                                        style: AppThemes.safeGeist(
                                          fontSize: 14,
                                          color: subColor,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          key: const ValueKey('cancel_overwrite_button'),
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text(
                                            'Cancel',
                                            style: AppThemes.safeGeist(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: subColor,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          key: const ValueKey('confirm_overwrite_button'),
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text(
                                            'Overwrite',
                                            style: AppThemes.safeGeist(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: accColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ) ?? false;
                                }

                                if (shouldImport && context.mounted) {
                                  final success = await ref.read(mediaProvider.notifier).importBackupJson(jsonString);
                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Backup imported successfully.', style: AppThemes.safeGeist(color: Colors.white)),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Import failed: Invalid backup file format.', style: AppThemes.safeGeist(color: Colors.white)),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Import failed: $e', style: AppThemes.safeGeist(color: Colors.white)),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: About
                    _buildSectionHeader('About', subColor),
                    _buildCard(context, 
                      cardBg,
                      isDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TMDB Attribution',
                              style: AppThemes.safeGeist(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: inkColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This product uses the TMDB API but is not endorsed or certified by TMDB.',
                              style: AppThemes.safeGeist(
                                fontSize: 13,
                                color: subColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tester Privacy Note',
                              style: AppThemes.safeGeist(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: inkColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'The Lounge collects local storage state to persist your watchlist, bookmarks, and preferences, as well as anonymous Sentry error and device logs to identify bugs and ensure stability.',
                              style: AppThemes.safeGeist(
                                fontSize: 13,
                                color: subColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'rOne',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 2.0,
                          color: subColor.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppThemes.safeGeist(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, Color bgColor, bool isDark, {required Widget child}) {
    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.ambianceColors.lineRgba,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
