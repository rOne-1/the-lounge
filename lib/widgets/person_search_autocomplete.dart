import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../providers/repository_provider.dart';
import '../utils/tmdb_image_helper.dart';

/// Autocomplete search widget for selecting cast or crew members in TMDB discover filters.
class PersonSearchAutocomplete extends ConsumerStatefulWidget {
  final bool isDark;

  const PersonSearchAutocomplete({
    super.key,
    this.isDark = true,
  });

  @override
  ConsumerState<PersonSearchAutocomplete> createState() =>
      _PersonSearchAutocompleteState();
}

class _PersonSearchAutocompleteState
    extends ConsumerState<PersonSearchAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isDropdownVisible = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
          _isDropdownVisible = _searchQuery.isNotEmpty;
        });
      }
    });
  }

  void _selectPerson(int personId, String personName) {
    ref.read(discoverFilterProvider.notifier).setPerson(
          personId: personId,
          personName: personName,
        );
    _controller.clear();
    setState(() {
      _searchQuery = '';
      _isDropdownVisible = false;
    });
    _focusNode.unfocus();
  }

  void _clearSelectedPerson() {
    ref.read(discoverFilterProvider.notifier).setPerson(
          personId: null,
          personName: null,
        );
    _controller.clear();
    setState(() {
      _searchQuery = '';
      _isDropdownVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final inkColor = context.ambianceColors.ink;
    final subColor = context.ambianceColors.sub;
    final lineRgba = context.ambianceColors.lineRgba;
    final pillColor = context.ambianceColors.pill;
    final cardBg = context.ambianceColors.card;

    final filterParams = ref.watch(discoverFilterProvider);
    final selectedPersonName = filterParams.personName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedPersonName != null && selectedPersonName.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: context.ambianceColors.primaryButtonDecoration.copyWith(borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      selectedPersonName,
                      style: AppThemes.safeGeist(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearSelectedPerson,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          // Without its own key, this field's internal Scrollable inherits
          // the enclosing ExpansionTile's PageStorageKey (see
          // _buildExpansionSection in browse_screen.dart) as its nearest
          // ancestor identity, and collides with the bool the ExpansionTile
          // itself stores there for its expanded/collapsed state --
          // restoreScrollOffset() then throws trying to read that bool as
          // a double scroll offset. A key of its own gives it an
          // independent PageStorage bucket.
          key: const PageStorageKey<String>('person_search_autocomplete_field'),
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onQueryChanged,
          onTap: () {
            if (_searchQuery.isNotEmpty) {
              setState(() {
                _isDropdownVisible = true;
              });
            }
          },
          style: AppThemes.safeGeist(fontSize: 13, color: inkColor),
          decoration: InputDecoration(
            hintText: selectedPersonName != null
                ? 'Change person...'
                : 'Search cast or crew...',
            hintStyle: AppThemes.safeGeist(fontSize: 13, color: subColor),
            prefixIcon: Icon(Icons.search, size: 18, color: subColor),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 16, color: subColor),
                    onPressed: () {
                      _controller.clear();
                      _onQueryChanged('');
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: pillColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: lineRgba),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: context.ambianceColors.acc,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_isDropdownVisible && _searchQuery.isNotEmpty) ...[
          const SizedBox(height: 6),
          Consumer(
            builder: (context, ref, _) {
              final searchAsync = ref.watch(searchPersonsProvider(_searchQuery));

              return searchAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lineRgba),
                      ),
                      child: Text(
                        'No matching person found.',
                        style: AppThemes.safeGeist(
                          fontSize: 12,
                          color: subColor,
                        ),
                      ),
                    );
                  }

                  return Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lineRgba),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 80 : 20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.separated(
                      // Same PageStorage-collision reasoning as the
                      // TextField's key above -- an unkeyed Scrollable here
                      // would also inherit the enclosing ExpansionTile's
                      // storage bucket.
                      key: const PageStorageKey<String>('person_search_autocomplete_results'),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: results.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: lineRgba,
                      ),
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final id = item['id'] as int?;
                        final name = item['name'] as String? ?? 'Unknown';
                        final dept = item['known_for_department'] as String?;
                        final profilePath = item['profile_path'] as String?;
                        final headshotUrl =
                            TmdbImageHelper.w185(profilePath);

                        if (id == null) return const SizedBox.shrink();

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: pillColor,
                            backgroundImage: headshotUrl != null
                                ? NetworkImage(headshotUrl)
                                : null,
                            child: headshotUrl == null
                                ? Icon(Icons.person, size: 18, color: subColor)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: AppThemes.safeGeist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: inkColor,
                            ),
                          ),
                          subtitle: dept != null && dept.isNotEmpty
                              ? Text(
                                  dept,
                                  style: AppThemes.safeGeist(
                                    fontSize: 11,
                                    color: subColor,
                                  ),
                                )
                              : null,
                          onTap: () => _selectPerson(id, name),
                        );
                      },
                    ),
                  ),
                );
                },
                loading: () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lineRgba),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (err, stack) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lineRgba),
                  ),
                  child: Text(
                    'Error searching people.',
                    style: AppThemes.safeGeist(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
