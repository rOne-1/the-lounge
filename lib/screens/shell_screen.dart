import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/ambiance_provider.dart';
import '../widgets/responsive_layout.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'discover_screen.dart';
import 'search_screen.dart';
import 'your_space_screen.dart';
import 'calendar_screen.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final ambiance = ref.watch(ambianceProvider);

    final navigationNotifier = ref.read(navigationProvider.notifier);
    final ambianceNotifier = ref.read(ambianceProvider.notifier);

    return ResponsiveLayout(
      compact: (context) => Scaffold(
        appBar: _buildAppBar(
            navigationState, navigationNotifier, ambiance, ambianceNotifier),
        body: _buildBody(navigationState.currentTab),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navigationState.currentTab.index,
          onTap: (index) => navigationNotifier.setTab(AppTab.values[index]),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.explore), label: 'Discover'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Your Space'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month), label: 'Calendar'),
          ],
        ),
      ),
      medium: (context) => Scaffold(
        appBar: _buildAppBar(
            navigationState, navigationNotifier, ambiance, ambianceNotifier),
        body: _buildMediumLargeLayout(navigationState, navigationNotifier),
      ),
      large: (context) => Scaffold(
        appBar: _buildAppBar(
            navigationState, navigationNotifier, ambiance, ambianceNotifier),
        body: _buildMediumLargeLayout(navigationState, navigationNotifier),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    NavigationState navigationState,
    NavigationNotifier navigationNotifier,
    AmbianceType ambiance,
    AmbianceNotifier ambianceNotifier,
  ) {
    return AppBar(
      title: const Text('The Lounge'),
      actions: [
        SegmentedButton<MediaTypeToggle>(
          segments: const [
            ButtonSegment<MediaTypeToggle>(
              value: MediaTypeToggle.movies,
              label: Text('Movies'),
              icon: Icon(Icons.movie),
            ),
            ButtonSegment<MediaTypeToggle>(
              value: MediaTypeToggle.tv,
              label: Text('TV'),
              icon: Icon(Icons.tv),
            ),
          ],
          selected: {navigationState.activeMediaType},
          onSelectionChanged: (Set<MediaTypeToggle> newSelection) {
            navigationNotifier.setMediaType(newSelection.first);
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            ambiance == AmbianceType.screeningRoom
                ? Icons.light_mode
                : Icons.dark_mode,
          ),
          onPressed: () {
            ambianceNotifier.toggleAmbiance();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMediumLargeLayout(
    NavigationState state,
    NavigationNotifier notifier,
  ) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: state.currentTab.index,
          onDestinationSelected: (index) =>
              notifier.setTab(AppTab.values[index]),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
                icon: Icon(Icons.home), label: Text('Home')),
            NavigationRailDestination(
                icon: Icon(Icons.explore), label: Text('Discover')),
            NavigationRailDestination(
                icon: Icon(Icons.search), label: Text('Search')),
            NavigationRailDestination(
                icon: Icon(Icons.person), label: Text('Your Space')),
            NavigationRailDestination(
                icon: Icon(Icons.calendar_month), label: Text('Calendar')),
          ],
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: _buildBody(state.currentTab),
        ),
      ],
    );
  }

  Widget _buildBody(AppTab tab) {
    switch (tab) {
      case AppTab.home:
        return const HomeScreen();
      case AppTab.discover:
        return const DiscoverScreen();
      case AppTab.search:
        return const SearchScreen();
      case AppTab.yourSpace:
        return const YourSpaceScreen();
      case AppTab.calendar:
        return const CalendarScreen();
    }
  }
}
