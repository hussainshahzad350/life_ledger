import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';

/// Quick-Add screen state (docs/05 §5.2). Opens on recents/favorites so the
/// common case is a single tap + confirm — the < 10 s promise (FR-10).
class QuickAddState extends Equatable {
  /// Creates a state.
  const QuickAddState({
    this.recents = const [],
    this.favorites = const [],
    this.searchResults = const [],
    this.query = '',
    this.loading = true,
    this.justLogged,
    this.failure,
  });

  /// Most-recently-logged foods.
  final List<FoodItem> recents;

  /// Favorite foods.
  final List<FoodItem> favorites;

  /// Current search results (empty when [query] is empty).
  final List<FoodItem> searchResults;

  /// The active search query.
  final String query;

  /// Whether recents/favorites are loading.
  final bool loading;

  /// The entry just logged (drives the confirmation snackbar); null once shown.
  final FoodEntry? justLogged;

  /// The last failure, if any.
  final Failure? failure;

  /// Copy with updates. [clearJustLogged] resets the one-shot signal.
  QuickAddState copyWith({
    List<FoodItem>? recents,
    List<FoodItem>? favorites,
    List<FoodItem>? searchResults,
    String? query,
    bool? loading,
    FoodEntry? justLogged,
    bool clearJustLogged = false,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return QuickAddState(
      recents: recents ?? this.recents,
      favorites: favorites ?? this.favorites,
      searchResults: searchResults ?? this.searchResults,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      justLogged: clearJustLogged ? null : (justLogged ?? this.justLogged),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    recents,
    favorites,
    searchResults,
    query,
    loading,
    justLogged,
    failure,
  ];
}

/// Drives the Quick-Add flow (docs/08 F3): load recents/favorites, search,
/// and one-tap logging with the time-of-day meal slot preselected.
class QuickAddCubit extends Cubit<QuickAddState> {
  /// Creates the cubit.
  QuickAddCubit({
    required FoodRepository repository,
    required LogFoodEntry logFoodEntry,
    required Clock clock,
    required String userId,
  }) : _repository = repository,
       _logFoodEntry = logFoodEntry,
       _clock = clock,
       _userId = userId,
       super(const QuickAddState());

  final FoodRepository _repository;
  final LogFoodEntry _logFoodEntry;
  final Clock _clock;
  final String _userId;

  /// The meal slot suggested for the current time (docs/05 §5.2).
  MealSlot get suggestedMeal => MealSlot.forHour(_clock.nowLocal().hour);

  /// Loads recents and favorites (called on open).
  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final recents = await _repository.recents(_userId);
    final favorites = await _repository.favorites(_userId);
    emit(
      state.copyWith(
        loading: false,
        recents: recents.valueOrNull ?? const [],
        favorites: favorites.valueOrNull ?? const [],
        failure: recents.failureOrNull ?? favorites.failureOrNull,
      ),
    );
  }

  /// Runs a catalog search; an empty query clears results.
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      emit(state.copyWith(query: '', searchResults: const []));
      return;
    }
    final result = await _repository.search(query.trim());
    emit(
      state.copyWith(
        query: query,
        searchResults: result.valueOrNull ?? const [],
      ),
    );
  }

  /// Logs [item] in [quantity] servings (defaults to the suggested meal),
  /// then refreshes recents. Emits [QuickAddState.justLogged] on success.
  Future<void> logFood(
    FoodItem item, {
    double quantity = 1,
    MealSlot? mealSlot,
  }) async {
    final result = await _logFoodEntry(
      userId: _userId,
      foodItemId: item.id,
      quantity: quantity,
      mealSlot: mealSlot ?? suggestedMeal,
    );
    if (result.failureOrNull case final failure?) {
      emit(state.copyWith(failure: failure));
      return;
    }
    emit(state.copyWith(justLogged: result.valueOrNull, clearFailure: true));
    await load();
  }

  /// Clears the one-shot "just logged" signal after the UI consumes it.
  void acknowledgeLogged() => emit(state.copyWith(clearJustLogged: true));
}
