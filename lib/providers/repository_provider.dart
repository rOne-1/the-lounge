import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/movie_repository.dart';
import '../repositories/mock_movie_repository.dart';

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MockMovieRepository();
});
