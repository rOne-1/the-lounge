import 'package:flutter/foundation.dart';

const _sentinel = Object();

/// Parameters for filtering server-side TMDB discover requests for movies and TV shows.
@immutable
class DiscoverFilterParams {
  final int? genreId;
  final String? genreName;
  final int? keywordId;
  final String? keywordName;
  final int? personId;
  final String? personName;
  final int? providerId;
  final String? providerName;
  final String? watchRegion;
  final int? minRuntime;
  final int? maxRuntime;
  final int? minVoteCount;
  final String? originalLanguage;
  final int? tvNetworkId;
  final String? tvNetworkName;
  final String? tvStatus;
  final String sortBy;
  final int? releaseYear;
  final double? minRating;

  /// LANG-2 (2nd pass, 2026-08-19): date-range filters used to approximate
  /// TMDB's dedicated now_playing/upcoming/airing_today/on_the_air
  /// endpoints via /discover when a Hall's language lock is active (those
  /// dedicated endpoints have no language filter at all -- see
  /// repository_provider.dart's fetchLanguageLockedDiscover). ISO
  /// 'YYYY-MM-DD' strings, matching TMDB's expected date format.
  final String? primaryReleaseDateGte;
  final String? primaryReleaseDateLte;
  final String? airDateGte;
  final String? airDateLte;

  const DiscoverFilterParams({
    this.genreId,
    this.genreName,
    this.keywordId,
    this.keywordName,
    this.personId,
    this.personName,
    this.providerId,
    this.providerName,
    this.watchRegion,
    this.minRuntime,
    this.maxRuntime,
    this.minVoteCount,
    this.originalLanguage,
    this.tvNetworkId,
    this.tvNetworkName,
    this.tvStatus,
    this.sortBy = 'popularity.desc',
    this.releaseYear,
    this.minRating,
    this.primaryReleaseDateGte,
    this.primaryReleaseDateLte,
    this.airDateGte,
    this.airDateLte,
  });

  /// Returns true if any filter other than sortBy is set.
  bool get hasActiveFilters {
    return genreId != null ||
        keywordId != null ||
        personId != null ||
        providerId != null ||
        minRuntime != null ||
        maxRuntime != null ||
        minVoteCount != null ||
        (originalLanguage != null && originalLanguage!.isNotEmpty) ||
        tvNetworkId != null ||
        (tvStatus != null && tvStatus!.isNotEmpty) ||
        releaseYear != null ||
        minRating != null ||
        primaryReleaseDateGte != null ||
        primaryReleaseDateLte != null ||
        airDateGte != null ||
        airDateLte != null;
  }

  DiscoverFilterParams copyWith({
    Object? genreId = _sentinel,
    Object? genreName = _sentinel,
    Object? keywordId = _sentinel,
    Object? keywordName = _sentinel,
    Object? personId = _sentinel,
    Object? personName = _sentinel,
    Object? providerId = _sentinel,
    Object? providerName = _sentinel,
    Object? watchRegion = _sentinel,
    Object? minRuntime = _sentinel,
    Object? maxRuntime = _sentinel,
    Object? minVoteCount = _sentinel,
    Object? originalLanguage = _sentinel,
    Object? tvNetworkId = _sentinel,
    Object? tvNetworkName = _sentinel,
    Object? tvStatus = _sentinel,
    String? sortBy,
    Object? releaseYear = _sentinel,
    Object? minRating = _sentinel,
    Object? primaryReleaseDateGte = _sentinel,
    Object? primaryReleaseDateLte = _sentinel,
    Object? airDateGte = _sentinel,
    Object? airDateLte = _sentinel,
  }) {
    return DiscoverFilterParams(
      genreId: genreId == _sentinel ? this.genreId : genreId as int?,
      genreName:
          genreName == _sentinel ? this.genreName : genreName as String?,
      keywordId:
          keywordId == _sentinel ? this.keywordId : keywordId as int?,
      keywordName:
          keywordName == _sentinel ? this.keywordName : keywordName as String?,
      personId: personId == _sentinel ? this.personId : personId as int?,
      personName:
          personName == _sentinel ? this.personName : personName as String?,
      providerId:
          providerId == _sentinel ? this.providerId : providerId as int?,
      providerName: providerName == _sentinel
          ? this.providerName
          : providerName as String?,
      watchRegion:
          watchRegion == _sentinel ? this.watchRegion : watchRegion as String?,
      minRuntime:
          minRuntime == _sentinel ? this.minRuntime : minRuntime as int?,
      maxRuntime:
          maxRuntime == _sentinel ? this.maxRuntime : maxRuntime as int?,
      minVoteCount:
          minVoteCount == _sentinel ? this.minVoteCount : minVoteCount as int?,
      originalLanguage: originalLanguage == _sentinel
          ? this.originalLanguage
          : originalLanguage as String?,
      tvNetworkId:
          tvNetworkId == _sentinel ? this.tvNetworkId : tvNetworkId as int?,
      tvNetworkName: tvNetworkName == _sentinel
          ? this.tvNetworkName
          : tvNetworkName as String?,
      tvStatus: tvStatus == _sentinel ? this.tvStatus : tvStatus as String?,
      sortBy: sortBy ?? this.sortBy,
      releaseYear:
          releaseYear == _sentinel ? this.releaseYear : releaseYear as int?,
      minRating:
          minRating == _sentinel ? this.minRating : minRating as double?,
      primaryReleaseDateGte: primaryReleaseDateGte == _sentinel
          ? this.primaryReleaseDateGte
          : primaryReleaseDateGte as String?,
      primaryReleaseDateLte: primaryReleaseDateLte == _sentinel
          ? this.primaryReleaseDateLte
          : primaryReleaseDateLte as String?,
      airDateGte:
          airDateGte == _sentinel ? this.airDateGte : airDateGte as String?,
      airDateLte:
          airDateLte == _sentinel ? this.airDateLte : airDateLte as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoverFilterParams &&
          runtimeType == other.runtimeType &&
          genreId == other.genreId &&
          genreName == other.genreName &&
          keywordId == other.keywordId &&
          keywordName == other.keywordName &&
          personId == other.personId &&
          personName == other.personName &&
          providerId == other.providerId &&
          providerName == other.providerName &&
          watchRegion == other.watchRegion &&
          minRuntime == other.minRuntime &&
          maxRuntime == other.maxRuntime &&
          minVoteCount == other.minVoteCount &&
          originalLanguage == other.originalLanguage &&
          tvNetworkId == other.tvNetworkId &&
          tvNetworkName == other.tvNetworkName &&
          tvStatus == other.tvStatus &&
          sortBy == other.sortBy &&
          releaseYear == other.releaseYear &&
          minRating == other.minRating &&
          primaryReleaseDateGte == other.primaryReleaseDateGte &&
          primaryReleaseDateLte == other.primaryReleaseDateLte &&
          airDateGte == other.airDateGte &&
          airDateLte == other.airDateLte;

  @override
  int get hashCode => Object.hashAll([
        genreId,
        genreName,
        keywordId,
        keywordName,
        personId,
        personName,
        providerId,
        providerName,
        watchRegion,
        minRuntime,
        maxRuntime,
        minVoteCount,
        originalLanguage,
        tvNetworkId,
        tvNetworkName,
        tvStatus,
        sortBy,
        releaseYear,
        minRating,
        primaryReleaseDateGte,
        primaryReleaseDateLte,
        airDateGte,
        airDateLte,
      ]);

  @override
  String toString() {
    return 'DiscoverFilterParams(genreId: $genreId, genreName: $genreName, keywordId: $keywordId, keywordName: $keywordName, personId: $personId, personName: $personName, providerId: $providerId, providerName: $providerName, watchRegion: $watchRegion, minRuntime: $minRuntime, maxRuntime: $maxRuntime, minVoteCount: $minVoteCount, originalLanguage: $originalLanguage, tvNetworkId: $tvNetworkId, tvNetworkName: $tvNetworkName, tvStatus: $tvStatus, sortBy: $sortBy, releaseYear: $releaseYear, minRating: $minRating, primaryReleaseDateGte: $primaryReleaseDateGte, primaryReleaseDateLte: $primaryReleaseDateLte, airDateGte: $airDateGte, airDateLte: $airDateLte)';
  }
}
