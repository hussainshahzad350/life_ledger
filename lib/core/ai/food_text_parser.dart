import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/ai/insight.dart';

/// A food the parser can match against (name + aliases from the catalog,
/// docs/17 §2.6).
class FoodLexeme extends Equatable {
  /// Creates a lexeme.
  const FoodLexeme({
    required this.id,
    required this.name,
    this.aliases = const [],
  });

  /// The `food_item` id this lexeme resolves to.
  final String id;

  /// Canonical (English) food name.
  final String name;

  /// Alternate names/spellings/transliterations (e.g. roti/chapati).
  final List<String> aliases;

  @override
  List<Object?> get props => [id, name, aliases];
}

/// One parsed segment of a natural-language food phrase.
///
/// Parsed results are **always confirmed by the user** before saving —
/// the parser never silently logs the wrong food (docs/07 §7).
class ParsedFoodCandidate extends Equatable {
  /// Creates a candidate.
  const ParsedFoodCandidate({
    required this.rawText,
    required this.quantity,
    this.unit,
    this.matchedFoodId,
    this.matchedName,
    required this.confidence,
  });

  /// The original segment text (for the confirmation UI).
  final String rawText;

  /// Parsed quantity (defaults to 1 when unstated).
  final double quantity;

  /// Parsed unit token when present (e.g. `cup`, `ml`, `g`, `slice`).
  final String? unit;

  /// Matched catalog food id, or null when nothing matched.
  final String? matchedFoodId;

  /// Matched catalog food name, or null.
  final String? matchedName;

  /// Match confidence: exact = high, partial = medium, none = low.
  final Confidence confidence;

  @override
  List<Object?> get props => [
    rawText,
    quantity,
    unit,
    matchedFoodId,
    matchedName,
    confidence,
  ];
}

/// Natural-language food logging interface (FR-15, docs/07 §7). The v1
/// implementation is deterministic; an on-device NLU model can replace it
/// behind this same interface (AI roadmap Phase 3).
abstract interface class FoodTextParser {
  /// Parses free text like `"2 eggs and toast"` into candidates.
  List<ParsedFoodCandidate> parse(String text);
}

/// v1 deterministic parser (docs/07 §7): tokenize → split segments on
/// `and`/commas → extract quantity (digits or number words) and an optional
/// unit → fuzzy-match the rest against the provided lexicon. No network,
/// no model, fully unit-testable.
class DeterministicFoodTextParser implements FoodTextParser {
  /// Creates a parser over the given catalog [lexicon].
  const DeterministicFoodTextParser(this.lexicon);

  /// The food names/aliases to match against.
  final List<FoodLexeme> lexicon;

  static const Map<String, double> _numberWords = {
    'a': 1,
    'an': 1,
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'half': 0.5,
  };

  static const Set<String> _units = {
    'g',
    'gram',
    'grams',
    'kg',
    'ml',
    'l',
    'litre',
    'liter',
    'cup',
    'cups',
    'glass',
    'glasses',
    'slice',
    'slices',
    'piece',
    'pieces',
    'tbsp',
    'tsp',
    'bowl',
    'plate',
  };

  @override
  List<ParsedFoodCandidate> parse(String text) {
    final segments = text
        .toLowerCase()
        .split(RegExp(r',|\band\b|\bwith\b'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return [for (final segment in segments) _parseSegment(segment)];
  }

  ParsedFoodCandidate _parseSegment(String segment) {
    final tokens = segment
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    var quantity = 1.0;
    String? unit;
    final nameTokens = <String>[];

    for (final token in tokens) {
      final asNumber = double.tryParse(token) ?? _numberWords[token];
      if (asNumber != null && nameTokens.isEmpty) {
        quantity = asNumber;
        continue;
      }
      if (_units.contains(token) && unit == null && nameTokens.isEmpty) {
        unit = _singular(token);
        continue;
      }
      nameTokens.add(token);
    }

    final query = nameTokens.join(' ');
    final match = _bestMatch(query);

    return ParsedFoodCandidate(
      rawText: segment,
      quantity: quantity,
      unit: unit,
      matchedFoodId: match?.$1.id,
      matchedName: match?.$1.name,
      confidence: match?.$2 ?? Confidence.low,
    );
  }

  /// Exact name/alias match (after singularizing) = high; prefix/contains
  /// match = medium; nothing = null (caller reports low + no match).
  (FoodLexeme, Confidence)? _bestMatch(String query) {
    if (query.isEmpty) return null;
    final normalized = _singular(query);

    for (final lexeme in lexicon) {
      final names = [
        lexeme.name,
        ...lexeme.aliases,
      ].map((n) => _singular(n.toLowerCase()));
      if (names.contains(normalized)) return (lexeme, Confidence.high);
    }
    for (final lexeme in lexicon) {
      final names = [
        lexeme.name,
        ...lexeme.aliases,
      ].map((n) => _singular(n.toLowerCase()));
      final partial = names.any(
        (n) => n.startsWith(normalized) || normalized.contains(n),
      );
      if (partial) return (lexeme, Confidence.medium);
    }
    return null;
  }

  static String _singular(String word) =>
      word.endsWith('s') && !word.endsWith('ss') && word.length > 3
      ? word.substring(0, word.length - 1)
      : word;
}
