# 🏛️ Multi-Profile & Medium-Partitioned Architecture Specification

**Author:** Antigravity AI  
**Status:** Approved Architectural Standard  
**Target Codebase:** `the-lounge`  
**Applies to:** Multi-Profile Engine, Medium Routing (Movies / TV / Anime), and Archive/Lounge State Systems

---

## 🌳 1. Core Hierarchy: The 3 × 3 Domain Matrix

The Lounge architecture is structured around two primary orthogonal axes:
1. **Tier 1 (Medium / Domain Axis):** The top-level 1st-class media domains (`Movies`, `TV`, `Anime`).
2. **Tier 2 (User Profile Axis):** 3 fully sandboxed user personas (`Profile 1 [Common]`, `Profile 2 [Custom]`, `Profile 3 [Custom]`).
3. **Tier 3 (Your Space / Archive Axis):** The user's personalized saved content partitioned by domain within each profile.

```
                                  TIER 1: MEDIUM / DOMAIN (Global Backend)
                      ┌───────────────────────┬───────────────────────┬───────────────────────┐
                      │        MOVIES         │          TV           │         ANIME         │
                      │        (TMDB)         │        (TMDB)         │   (AniList GraphQL)   │
                      └───────────┬───────────┴───────────┬───────────┴───────────┬───────────┘
                                  │                       │                       │
         ═════════════════════════╪═══════════════════════╪═══════════════════════╪═════════════════════════
                                  ▼                       ▼                       ▼
                                           TIER 2: PROFILES (User Personas)
                      ┌───────────────────────┬───────────────────────┬───────────────────────┐
                      │       PROFILE 1       │       PROFILE 2       │       PROFILE 3       │
                      │       (Common)        │       (Custom)        │       (Custom)        │
                      └───────────┬───────────┴───────────┬───────────┴───────────┬───────────┘
                                  │                       │                       │
         ═════════════════════════╪═══════════════════════╪═══════════════════════╪═════════════════════════
                                  ▼                       ▼                       ▼
                                      TIER 3: YOUR SPACE / ARCHIVE (Per-Profile Data)
                      ┌───────────────────────┐┌───────────────────────┐┌───────────────────────┐
                      │      YOUR SPACE       ││      YOUR SPACE       ││      YOUR SPACE       │
                      │  • Movies Archive     ││  • Movies Archive     ││  • Movies Archive     │
                      │  • TV Archive         ││  • TV Archive         ││  • TV Archive         │
                      │  • Anime Archive      ││  • Anime Archive      ││  • Anime Archive      │
                      │  • Custom Folders     ││  • Custom Folders     ││  • Custom Folders     │
                      │  • Notes & Ratings    ││  • Notes & Ratings    ││  • Notes & Ratings    │
                      └───────────────────────┘└───────────────────────┘└───────────────────────┘
```

---

## 📐 2. Data Structure Specification (`ProfileArchiveStore`)

Rather than relying on flat lists with runtime $O(N)$ filtering or exploding storage keys, each profile encapsulates a 2D **Domain Map** (`Map<MediumDomain, DomainArchive>`):

```dart
/// The Top-Level 1st-Class Medium Vertical
enum MediumDomain {
  movies,
  tv,
  anime;

  String get displayName {
    switch (this) {
      case MediumDomain.movies:
        return 'Movies';
      case MediumDomain.tv:
        return 'TV Shows';
      case MediumDomain.anime:
        return 'Anime';
    }
  }
}

/// The 6 Universal Status Buckets inside any Domain
enum ArchiveBucket {
  watching,
  watchlist,
  watched,
  saved,
  onHold,
  dropped;
}

/// A Domain-Specific Sandboxed Archive (e.g. Profile 2 -> TV)
class DomainArchive {
  final Map<String, MediaItem> watching;
  final Map<String, MediaItem> watchlist;
  final Map<String, MediaItem> watched;
  final Map<String, MediaItem> saved;
  final Map<String, MediaItem> onHold;
  final Map<String, MediaItem> dropped;
  final Map<String, Set<String>> watchedEpisodes; // showId -> Set<'S1E1'>

  const DomainArchive({
    this.watching = const {},
    this.watchlist = const {},
    this.watched = const {},
    this.saved = const {},
    this.onHold = const {},
    this.dropped = const {},
    this.watchedEpisodes = const {},
  });

  int get totalCount =>
      watching.length +
      watchlist.length +
      watched.length +
      saved.length +
      onHold.length +
      dropped.length;

  Map<String, dynamic> toJson() => {
        'watching': watching.map((k, v) => MapEntry(k, v.toJson())),
        'watchlist': watchlist.map((k, v) => MapEntry(k, v.toJson())),
        'watched': watched.map((k, v) => MapEntry(k, v.toJson())),
        'saved': saved.map((k, v) => MapEntry(k, v.toJson())),
        'onHold': onHold.map((k, v) => MapEntry(k, v.toJson())),
        'dropped': dropped.map((k, v) => MapEntry(k, v.toJson())),
        'watchedEpisodes':
            watchedEpisodes.map((k, v) => MapEntry(k, v.toList())),
      };
}

/// The Self-Contained Profile Container
class ProfileSpace {
  final String id;          // 'common', 'custom_1', 'custom_2'
  final String name;        // 'Common', 'Cinema Buff', 'Late Night Anime'
  final String iconKey;
  final bool isCommon;
  
  /// The 2D Partitioned Domain Store
  final Map<MediumDomain, DomainArchive> domains;
  
  /// Profile-level shared collections & metadata
  final List<CustomFolder> customFolders;
  final Map<String, UserNoteRating> notesAndRatings;

  const ProfileSpace({
    required this.id,
    required this.name,
    required this.iconKey,
    this.isCommon = false,
    required this.domains,
    this.customFolders = const [],
    this.notesAndRatings = const {},
  });

  /// O(1) Instant accessor for the active domain
  DomainArchive archiveFor(MediumDomain domain) =>
      domains[domain] ?? const DomainArchive();
}
```

---

## ⚡ 3. Key Architectural Guarantees

1. **$O(1)$ Instant Data Access:**
   Accessing the TV watchlist for Profile 2 is a direct hash lookup (`profileSpace.archiveFor(MediumDomain.tv).watchlist`). No scanning or runtime array filtering.
2. **AniList Anime Drop-In:**
   The future AniList GraphQL module simply populates `domains[MediumDomain.anime]`. The Movies & TV repositories and models remain 100% untouched.
3. **Atomic Profile Export & Backup:**
   Backing up or restoring a profile is a single JSON document (`profileSpace.toJson()`), eliminating fragmented multi-key synchronization errors.
4. **Hermetic Sandbox Isolation:**
   Saves in "Anime" under Profile 3 can never bleed into "Movies" under Profile 1.
5. **Zero-Lag Reactivity on Media Toggle:**
   Toggling between Movies, TV, and Anime in the navigation pill switches the pointer synchronously without expensive re-renders.
