import 'dart:async';
import '../models/media_item.dart';
import 'movie_repository.dart';

class MockMovieRepository implements MovieRepository {
  final List<MediaItem> _mockData = [
    MediaItem(
      id: '1',
      title: 'Inception',
      type: MediaType.movie,
      rating: 8.8,
      releaseOrAirDate: DateTime(2010, 7, 16),
      overview:
          'A thief who steals corporate secrets through the use of dream-sharing technology...',
      genres: ['Action', 'Sci-Fi', 'Thriller'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/8ZTVqvKDQ8emSGUEMjsS4yHAwrp.jpg',
      runtime: 148,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Netflix', 'Amazon Prime'],
      cast: [
        'Leonardo DiCaprio',
        'Joseph Gordon-Levitt',
        'Elliot Page',
        'Tom Hardy'
      ],
    ),
    MediaItem(
      id: '2',
      title: 'Stranger Things',
      type: MediaType.tv,
      rating: 8.7,
      releaseOrAirDate: DateTime(2016, 7, 15),
      overview:
          'When a young boy vanishes, a small town uncovers a mystery involving secret experiments...',
      genres: ['Sci-Fi & Fantasy', 'Drama', 'Mystery'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8Os2j1nOS.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/56v2KjBlU4XaOv9rVYEQypROD7P.jpg',
      seasonsCount: 4,
      episodesCount: 34,
      episodesList: [
        'Chapter One: The Vanishing of Will Byers',
        'Chapter Two: The Weirdo on Maple Street'
      ],
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Netflix'],
      cast: [
        'Millie Bobby Brown',
        'Winona Ryder',
        'David Harbour',
        'Finn Wolfhard'
      ],
    ),
    MediaItem(
      id: '3',
      title: 'The Dark Knight',
      type: MediaType.movie,
      rating: 9.0,
      releaseOrAirDate: DateTime(2008, 7, 18),
      overview:
          'When the menace known as the Joker wreaks havoc and chaos on the people of Gotham...',
      genres: ['Drama', 'Action', 'Crime', 'Thriller'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/dqK9Hag1054tghRQSqLSfrkvQnA.jpg',
      runtime: 152,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['HBO Max'],
      cast: [
        'Christian Bale',
        'Heath Ledger',
        'Aaron Eckhart',
        'Michael Caine'
      ],
    ),
    MediaItem(
      id: '4',
      title: 'Breaking Bad',
      type: MediaType.tv,
      rating: 9.5,
      releaseOrAirDate: DateTime(2008, 1, 20),
      overview:
          'A high school chemistry teacher diagnosed with inoperable lung cancer turns to manufacturing...',
      genres: ['Drama', 'Crime'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg',
      seasonsCount: 5,
      episodesCount: 62,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Netflix'],
      cast: ['Bryan Cranston', 'Aaron Paul', 'Anna Gunn', 'Dean Norris'],
    ),
    MediaItem(
      id: '5',
      title: 'The Room',
      type: MediaType.movie,
      rating: 3.6,
      releaseOrAirDate: DateTime(2003, 6, 27),
      overview:
          'Johnny is a successful banker who lives happily in a San Francisco townhouse with his fiancée...',
      genres: ['Drama', 'Romance'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/shqWevQ9K00rI3y5O3VpA7wYh4L.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/uVOPn3e9K9P84e0tF9J0mRry44n.jpg',
      runtime: 99,
      hasTrailer: false,
      watchProviders: [],
      cast: ['Tommy Wiseau', 'Greg Sestero', 'Juliette Danielle'],
    ),
    MediaItem(
      id: '6',
      title: 'Missing Image Movie',
      type: MediaType.movie,
      rating: 7.0,
      releaseOrAirDate: DateTime(2022, 1, 1),
      overview:
          'This movie has a broken image URL to test fallback mechanisms.',
      genres: ['Comedy'],
      posterUrl: 'https://example.com/broken_image.jpg',
      backdropUrl: 'https://example.com/broken_backdrop.jpg',
      runtime: 120,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      imageLoadWillFail: true,
      watchProviders: ['Hulu'],
      cast: ['John Doe', 'Jane Smith'],
    ),
    MediaItem(
      id: '7',
      title: 'The Matrix',
      type: MediaType.movie,
      rating: 8.7,
      releaseOrAirDate: DateTime(1999, 3, 31),
      overview:
          'A computer hacker learns from mysterious rebels about the true nature of his reality...',
      genres: ['Action', 'Sci-Fi'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/f89U3ADr1oiB1s9GvwJwB02xc1Y.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/ncEsesgOJDNrTUED89hYbA117jy.jpg',
      runtime: 136,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['HBO Max'],
      cast: [
        'Keanu Reeves',
        'Laurence Fishburne',
        'Carrie-Anne Moss',
        'Hugo Weaving'
      ],
    ),
    MediaItem(
      id: '8',
      title: 'The Office',
      type: MediaType.tv,
      rating: 8.9,
      releaseOrAirDate: DateTime(2005, 3, 24),
      overview:
          'A mockumentary on a group of typical office workers, where the workday consists of ego clashes...',
      genres: ['Comedy'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/qWnJzyZhyy74gjpSj10i0ZQ446n.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/KulfvwLq78f4u4n1uX3qX4n7y2.jpg',
      seasonsCount: 9,
      episodesCount: 201,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Peacock'],
      cast: ['Steve Carell', 'Rainn Wilson', 'John Krasinski', 'Jenna Fischer'],
    ),
    MediaItem(
      id: '9',
      title: 'Interstellar',
      type: MediaType.movie,
      rating: 8.6,
      releaseOrAirDate: DateTime(2014, 11, 5),
      overview:
          'A team of explorers travel through a wormhole in space in an attempt to ensure humanity\'s survival.',
      genres: ['Adventure', 'Drama', 'Sci-Fi'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/xJHokMbljvjEVAz543vPhkCPEm5.jpg',
      runtime: 169,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Paramount+'],
      cast: [
        'Matthew McConaughey',
        'Anne Hathaway',
        'Jessica Chastain',
        'Michael Caine'
      ],
    ),
    MediaItem(
      id: '10',
      title: 'Game of Thrones',
      type: MediaType.tv,
      rating: 9.3,
      releaseOrAirDate: DateTime(2011, 4, 17),
      overview:
          'Nine noble families fight for control over the lands of Westeros, while an ancient enemy returns...',
      genres: ['Sci-Fi & Fantasy', 'Drama', 'Action & Adventure'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/u3bZgnGQ9T01sWNhyveQz0wH0Hl.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/suopoADq0k8YZr4dQXcU6pToj6s.jpg',
      seasonsCount: 8,
      episodesCount: 73,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['HBO Max'],
      cast: ['Emilia Clarke', 'Kit Harington', 'Peter Dinklage', 'Lena Headey'],
    ),
    MediaItem(
      id: '11',
      title: 'Avatar',
      type: MediaType.movie,
      rating: 7.9,
      releaseOrAirDate: DateTime(2009, 12, 18),
      overview:
          'A paraplegic Marine dispatched to the moon Pandora on a unique mission becomes torn...',
      genres: ['Action', 'Adventure', 'Fantasy', 'Sci-Fi'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/jRXYjXNqtl10K2H4Uj057T3H638.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/vL5LR6WdxWPjUUegeVkVqBMyA.jpg',
      runtime: 162,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Disney+'],
      cast: [
        'Sam Worthington',
        'Zoe Saldaña',
        'Sigourney Weaver',
        'Stephen Lang'
      ],
    ),
    MediaItem(
      id: '12',
      title: 'The Mandalorian',
      type: MediaType.tv,
      rating: 8.7,
      releaseOrAirDate: DateTime(2019, 11, 12),
      overview:
          'After the fall of the Galactic Empire, lawlessness has spread throughout the galaxy...',
      genres: ['Sci-Fi & Fantasy', 'Action & Adventure', 'Drama'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/eU1i6eHXlzMOlEq0ku1Rzq7Y4wA.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/sjx6zjQI2dLGtEL0HGWsnq6UyLU.jpg',
      seasonsCount: 3,
      episodesCount: 24,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Disney+'],
      cast: [
        'Pedro Pascal',
        'Carl Weathers',
        'Giancarlo Esposito',
        'Katee Sackhoff'
      ],
    ),
    MediaItem(
      id: '13',
      title: 'Pulp Fiction',
      type: MediaType.movie,
      rating: 8.9,
      releaseOrAirDate: DateTime(1994, 10, 14),
      overview:
          'The lives of two mob hitmen, a boxer, a gangster and his wife, and a pair of diner bandits...',
      genres: ['Thriller', 'Crime'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/d5iIlFn5s0ImszYzBPbOYKQscreen.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/suaEOtk1N1sgg2MTM7oZd2cfVp3.jpg',
      runtime: 154,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Paramount+'],
      cast: [
        'John Travolta',
        'Samuel L. Jackson',
        'Uma Thurman',
        'Bruce Willis'
      ],
    ),
    MediaItem(
      id: '14',
      title: 'Friends',
      type: MediaType.tv,
      rating: 8.9,
      releaseOrAirDate: DateTime(1994, 9, 22),
      overview:
          'Follows the personal and professional lives of six twenty to thirty-something-year-old friends...',
      genres: ['Comedy', 'Drama'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/f496cm9enuEsZkSPzCwnTESEK5s.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/l0qVZIpXtIo7km9u5Yqh0nKPOr5.jpg',
      seasonsCount: 10,
      episodesCount: 236,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['HBO Max'],
      cast: [
        'Jennifer Aniston',
        'Courteney Cox',
        'Lisa Kudrow',
        'Matt LeBlanc',
        'Matthew Perry',
        'David Schwimmer'
      ],
    ),
    MediaItem(
      id: '15',
      title: 'Fight Club',
      type: MediaType.movie,
      rating: 8.8,
      releaseOrAirDate: DateTime(1999, 10, 15),
      overview:
          'An insomniac office worker and a devil-may-care soapmaker form an underground fight club...',
      genres: ['Drama'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/hZkgoQYus5vesz7cgEz7Ieb3y2m.jpg',
      runtime: 139,
      hasTrailer: false,
      watchProviders: ['Hulu'],
      cast: ['Edward Norton', 'Brad Pitt', 'Helena Bonham Carter', 'Meat Loaf'],
    ),
    MediaItem(
      id: '16',
      title: 'Better Call Saul',
      type: MediaType.tv,
      rating: 8.9,
      releaseOrAirDate: DateTime(2015, 2, 8),
      overview:
          'The trials and tribulations of criminal lawyer Jimmy McGill in the time leading up to...',
      genres: ['Crime', 'Drama'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/fC2HDm5t0kHlAMO3FfaQxTpiQj3.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/zFmP1M3oUjE7A3yXzB2hZpTQQjU.jpg',
      seasonsCount: 6,
      episodesCount: 63,
      hasTrailer: true,
      trailerVideoId: 'dQw4w9WgXcQ',
      watchProviders: ['Netflix', 'AMC+'],
      cast: [
        'Bob Odenkirk',
        'Jonathan Banks',
        'Rhea Seehorn',
        'Patrick Fabian'
      ],
    ),
    MediaItem(
      id: '17',
      title: 'Spider-Man: Across the Spider-Verse',
      type: MediaType.movie,
      rating: 8.8,
      releaseOrAirDate: DateTime(2023, 6, 2),
      overview:
          'Miles Morales catapults across the Multiverse, where he encounters a team of Spider-People...',
      genres: ['Action', 'Adventure', 'Animation', 'Science Fiction'],
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8Vt6mWEReuy4Of61Lnj5Xj704m8.jpg',
      backdropUrl:
          'https://image.tmdb.org/t/p/original/4HodYYKEIsGOdinkGi2Ucz6X9i0.jpg',
      runtime: 140,
      hasTrailer: true,
      watchProviders: ['Netflix'],
      cast: [
        'Shameik Moore',
        'Hailee Steinfeld',
        'Brian Tyree Henry',
        'Luna Lauren Velez'
      ],
    ),
  ];

  @override
  Future<List<MediaItem>> getTrendingMovies() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockData.where((m) => m.type == MediaType.movie).toList();
  }

  @override
  Future<List<MediaItem>> getPopularMovies() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockData
        .where((m) => m.type == MediaType.movie)
        .skip(5)
        .take(5)
        .toList();
  }

  @override
  Future<List<MediaItem>> getTrendingTvShows() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockData.where((m) => m.type == MediaType.tv).toList();
  }

  @override
  Future<MediaItem?> getMediaDetails(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final cleanId = id.replaceFirst(RegExp(r'^(movie_|tv_)'), '');
    try {
      return _mockData.firstWhere((m) => m.id == id || m.id == cleanId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<MediaItem>> searchMedia(String query) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final lowerQuery = query.toLowerCase();
    return _mockData.where((m) {
      final titleMatch = m.title.toLowerCase().contains(lowerQuery);
      final castMatch =
          m.cast.any((actor) => actor.toLowerCase().contains(lowerQuery));
      return titleMatch || castMatch;
    }).toList();
  }

  @override
  Future<List<Map<String, String>>> getWatchProviderRegions() async {
    return const [
      {'code': 'US', 'name': 'United States'},
      {'code': 'GB', 'name': 'United Kingdom'},
      {'code': 'CA', 'name': 'Canada'},
      {'code': 'AU', 'name': 'Australia'},
      {'code': 'DE', 'name': 'Germany'},
      {'code': 'FR', 'name': 'France'},
      {'code': 'JP', 'name': 'Japan'},
    ];
  }
}
