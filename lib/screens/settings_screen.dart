import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/media_provider.dart';
import '../providers/ambiance_provider.dart';
import '../providers/hall_provider.dart';
import '../services/hall_storage_service.dart';
import '../constants.dart';
import '../utils/export_helper.dart';
import '../widgets/animated_segmented_control.dart';
import '../widgets/lounge_dialog.dart';
import '../widgets/lounge_toast.dart';
import '../widgets/pressable_scale.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../services/api_call_tracker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // E8/TF-1: dev-confirmed intent is a deliberate blocking state during
  // backup/import/reset, not just a progress indicator -- the whole screen
  // is intentionally frozen on a loading page until the operation
  // completes, per _BlockingLoadingOverlay below.
  String? _busyMessage;

  Future<T> _runBusy<T>(String message, Future<T> Function() action) async {
    setState(() => _busyMessage = message);
    try {
      return await action();
    } finally {
      if (mounted) setState(() => _busyMessage = null);
    }
  }

  /// BACKUP-1: routes an imported file to whichever importer actually
  /// understands its dialect. New exports are HallStorageService's v4
  /// multi-hall schema (`schema_version`) -- old backups saved by a
  /// previous version of this screen are MediaNotifier's own single-hall
  /// schema (`version`), whose field names (e.g. `watchedList`) don't all
  /// match HallStorageService's own legacy-format key fallbacks
  /// (`watched_list`/`watched_items`), so routing every file through the
  /// new importer would silently drop most piles from an old backup.
  Future<bool> _importBackup(WidgetRef ref, String jsonString) async {
    Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(jsonString);
      if (raw is! Map<String, dynamic>) return false;
      decoded = raw;
    } catch (_) {
      return false;
    }

    ref.read(isDataImportingProvider.notifier).set(true);
    try {
      if (decoded.containsKey('schema_version')) {
        final halls = HallStorageService().importBackupJson(jsonString);
        if (halls.isEmpty) return false;
        await ref.read(hallProvider.notifier).applyImportedHalls(halls);
        return true;
      }

      if (decoded.containsKey('version')) {
        return ref.read(mediaProvider.notifier).importBackupJson(jsonString);
      }

      return false;
    } finally {
      ref.read(isDataImportingProvider.notifier).set(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ambiance = ref.watch(ambianceProvider);
    final isDark = context.ambianceColors.isDark;
    final mediaState = ref.watch(mediaProvider);

    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final accColor = context.ambianceColors.acc;
    final cardBg = context.ambianceColors.card;

    final bgDeco = context.ambianceColors.background;

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                  scrollCacheExtent: const ScrollCacheExtent.pixels(5000),
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
                            AnimatedSegmentedControl<AppTheme>(
                              items: allThemes,
                              selectedItem: ambiance,
                              labelBuilder: (theme) => theme.displayName.split(' ').first,
                              onSelected: (theme) {
                                ref.read(ambianceProvider.notifier).setAmbiance(theme);
                              },
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
                              // BACKUP-1: multi-hall v4 export (all 3 Halls,
                              // not just the active one) -- see
                              // HallStorageService for the schema and
                              // applyImportedHalls for the matching restore
                              // path. Reads fresh from SharedPreferences
                              // rather than hallProvider's cached state:
                              // hallProvider only rebuilds on a hall
                              // switch, so its cache can be stale relative
                              // to mediaProvider mutations made since.
                              final storageService = HallStorageService();
                              final prefs = ref.read(sharedPreferencesProvider);
                              final jsonString = storageService.exportFullBackupJson(
                                halls: storageService.loadAllHallsSync(prefs),
                                activeHallId: storageService.getActiveHallId(prefs),
                                themeId: ambiance.id,
                              );
                              try {
                                final success = await _runBusy(
                                  'Exporting your backup…',
                                  () => saveJsonFile(jsonString, 'the_lounge_backup.json'),
                                );
                                if (success && context.mounted) {
                                  LoungeToast.show(context, 'Backup exported successfully.', type: ToastType.success);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  LoungeToast.show(context, 'Export failed: $e', type: ToastType.danger);
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
                              'Share your archive data file directly',
                              style: AppThemes.safeGeist(fontSize: 12, color: subColor),
                            ),
                            onTap: () async {
                              final storageService = HallStorageService();
                              final prefs = ref.read(sharedPreferencesProvider);
                              final jsonString = storageService.exportFullBackupJson(
                                halls: storageService.loadAllHallsSync(prefs),
                                activeHallId: storageService.getActiveHallId(prefs),
                                themeId: ambiance.id,
                              );
                              try {
                                await _runBusy(
                                  'Preparing your backup…',
                                  () => shareJsonFile(jsonString, 'the_lounge_backup.json'),
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  LoungeToast.show(context, 'Share failed: $e', type: ToastType.danger);
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
                              'Restore your archive from a JSON file',
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
                                  shouldImport = await LoungeDialog.show<bool>(
                                    context,
                                    title: 'Overwrite current data?',
                                    message: 'This will replace all your current watchlists, watch history, and settings. Are you sure you want to overwrite?',
                                    actions: [
                                      LoungeDialogAction(
                                        key: const ValueKey('cancel_overwrite_button'),
                                        label: 'Cancel',
                                        onPressed: () => Navigator.of(context).pop(false),
                                      ),
                                      LoungeDialogAction(
                                        key: const ValueKey('confirm_overwrite_button'),
                                        label: 'Overwrite',
                                        style: LoungeDialogActionStyle.primary,
                                        onPressed: () => Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ) ?? false;
                                }

                                if (shouldImport && context.mounted) {
                                  final success = await _runBusy(
                                    'Importing your backup…',
                                    () => _importBackup(ref, jsonString),
                                  );
                                  if (context.mounted) {
                                    if (success) {
                                      LoungeToast.show(context, 'Backup imported successfully.', type: ToastType.success);
                                    } else {
                                      LoungeToast.show(context, 'Import failed: Invalid backup file format.', type: ToastType.danger);
                                    }
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  LoungeToast.show(context, 'Import failed: $e', type: ToastType.danger);
                                }
                              }
                            },
                          ),
                          Divider(color: context.ambianceColors.lineRgba, height: 1),
                          ListTile(
                            key: const ValueKey('reset_account_button'),
                            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            title: Text(
                              'Reset Account',
                              style: AppThemes.safeGeist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: inkColor,
                              ),
                            ),
                            subtitle: Text(
                              'Erase all local data and preferences',
                              style: AppThemes.safeGeist(fontSize: 12, color: subColor),
                            ),
                            onTap: () async {
                              final shouldReset = await LoungeDialog.show<bool>(
                                context,
                                title: 'Reset everything?',
                                message: 'This will delete all your local data, including watchlists and history. This action cannot be undone.',
                                actions: [
                                  LoungeDialogAction(
                                    label: 'Cancel',
                                    onPressed: () => Navigator.of(context).pop(false),
                                  ),
                                  LoungeDialogAction(
                                    label: 'Export Backup',
                                    onPressed: () async {
                                      final jsonString = ref.read(mediaProvider.notifier).exportBackupJson(ambiance.id);
                                      await saveJsonFile(jsonString, 'the_lounge_backup.json');
                                    },
                                  ),
                                  LoungeDialogAction(
                                    label: 'Reset Everything',
                                    style: LoungeDialogActionStyle.destructive,
                                    onPressed: () => Navigator.of(context).pop(true),
                                  ),
                                ],
                              ) ?? false;

                              if (shouldReset && context.mounted) {
                                await _runBusy(
                                  'Resetting your data…',
                                  () => ref.read(mediaProvider.notifier).clearAllData(),
                                );
                                if (context.mounted) {
                                  LoungeToast.show(context, 'Account reset successfully.', type: ToastType.success);
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

                    // E6: session-only API call/error counters + crash
                    // reporting mode, for testers to glance at without
                    // needing Sentry dashboard access.
                    _buildSectionHeader('Debug', subColor),
                    _buildCard(
                      context,
                      cardBg,
                      isDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListenableBuilder(
                          listenable: ApiCallTracker.instance,
                          builder: (context, _) {
                            final tracker = ApiCallTracker.instance;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'TMDB calls this session',
                                      style: AppThemes.safeGeist(fontSize: 13, color: subColor),
                                    ),
                                    Text(
                                      '${tracker.totalCalls}',
                                      style: AppThemes.safeGeist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: inkColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Failed calls',
                                      style: AppThemes.safeGeist(fontSize: 13, color: subColor),
                                    ),
                                    Text(
                                      '${tracker.failedCalls}',
                                      style: AppThemes.safeGeist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: tracker.failedCalls > 0
                                            ? context.ambianceColors.danger
                                            : inkColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Crash reporting',
                                      style: AppThemes.safeGeist(fontSize: 13, color: subColor),
                                    ),
                                    Text(
                                      Sentry.isEnabled ? 'Active' : 'Local logging only',
                                      style: AppThemes.safeGeist(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: inkColor,
                                      ),
                                    ),
                                  ],
                                ),
                                if (tracker.failureRecords.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  PressableScale(
                                    key: const ValueKey('copy_api_failures_button'),
                                    onTap: () {
                                      final jsonStr = tracker.exportFailuresJsonPretty();
                                      Clipboard.setData(ClipboardData(text: jsonStr));
                                      LoungeToast.show(
                                        context,
                                        'Copied ${tracker.failureRecords.length} API failure log${tracker.failureRecords.length == 1 ? '' : 's'} (JSON)',
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: context.ambianceColors.card2.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: context.ambianceColors.lineRgba),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.copy_rounded,
                                            size: 14,
                                            color: context.ambianceColors.ink,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Copy API Failures (JSON)',
                                            style: AppThemes.safeGeist(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: context.ambianceColors.ink,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 16),
                    _DeveloperSignature(subColor: subColor),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
          if (_busyMessage != null) _BlockingLoadingOverlay(message: _busyMessage!),
        ],
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

class _DeveloperSignature extends StatefulWidget {
  final Color subColor;
  
  const _DeveloperSignature({required this.subColor});

  @override
  State<_DeveloperSignature> createState() => _DeveloperSignatureState();
}

class _DeveloperSignatureState extends State<_DeveloperSignature> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    _opacityAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);

    // Prevent pumpAndSettle timeouts in widget tests
    final isTest = WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');
    if (!isTest) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: AnimatedBuilder(
        animation: _opacityAnim,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnim.value,
            child: child,
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CRAFTED BY',
              style: AppThemes.safeGeist(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
                color: widget.subColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 1.2,
                  color: context.ambianceColors.lineRgba.withValues(alpha: 0.65),
                ),
                const SizedBox(width: 14),
                Text(
                  'rOne',
                  style: GoogleFonts.bodoniModa(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 2.5,
                    color: widget.subColor.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 24,
                  height: 1.2,
                  color: context.ambianceColors.lineRgba.withValues(alpha: 0.65),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// E8/TF-1: a deliberate, opaque blocking state during backup/import/reset
/// -- not a stock spinner-in-a-dialog, but a full-screen page matching the
/// app's own screening-room identity (see SplashScreen), so an operation
/// that must not be interrupted reads as an intentional moment rather than
/// a stalled app.
class _BlockingLoadingOverlay extends StatelessWidget {
  final String message;

  const _BlockingLoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    final ambianceColors = context.ambianceColors;

    return Positioned.fill(
      child: AbsorbPointer(
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: AppPhysics.houseSpringDuration,
          curve: AppPhysics.houseSpringCurve,
          child: Container(
            decoration: ambianceColors.background.copyWith(
              color: ambianceColors.base,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: ambianceColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ambianceColors.acc.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ambianceColors.acc.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(ambianceColors.acc),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.bodoniModa(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: ambianceColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please don\'t close the app',
                    style: AppThemes.safeGeist(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: ambianceColors.acc,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
