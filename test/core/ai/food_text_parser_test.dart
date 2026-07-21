import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/food_text_parser.dart';
import 'package:life_ledger/core/ai/insight.dart';

void main() {
  const lexicon = [
    FoodLexeme(id: 'f-egg', name: 'Egg'),
    FoodLexeme(id: 'f-toast', name: 'Toast'),
    FoodLexeme(id: 'f-rice', name: 'Rice'),
    FoodLexeme(id: 'f-milk', name: 'Milk'),
    FoodLexeme(id: 'f-roti', name: 'Roti', aliases: ['chapati', 'phulka']),
    FoodLexeme(id: 'f-yogurt', name: 'Greek yogurt', aliases: ['dahi']),
  ];
  const parser = DeterministicFoodTextParser(lexicon);

  group('DeterministicFoodTextParser (docs/07 §7)', () {
    test('parses the canonical example: "2 eggs and toast"', () {
      final result = parser.parse('2 eggs and toast');
      expect(result, hasLength(2));

      expect(result[0].quantity, 2);
      expect(result[0].matchedFoodId, 'f-egg');
      expect(result[0].confidence, Confidence.high);

      expect(result[1].quantity, 1);
      expect(result[1].matchedFoodId, 'f-toast');
      expect(result[1].confidence, Confidence.high);
    });

    test('parses number words and units: "one cup rice"', () {
      final result = parser.parse('one cup rice').single;
      expect(result.quantity, 1);
      expect(result.unit, 'cup');
      expect(result.matchedFoodId, 'f-rice');
    });

    test('parses numeric quantities with units: "250 ml milk"', () {
      final result = parser.parse('250 ml milk').single;
      expect(result.quantity, 250);
      expect(result.unit, 'ml');
      expect(result.matchedFoodId, 'f-milk');
    });

    test('matches localized aliases: chapati → Roti (docs/17 §2.6)', () {
      final result = parser.parse('2 chapati').single;
      expect(result.matchedFoodId, 'f-roti');
      expect(result.matchedName, 'Roti');
      expect(result.confidence, Confidence.high);
    });

    test('partial matches get medium confidence, for user confirmation', () {
      final result = parser.parse('greek').single;
      expect(result.matchedFoodId, 'f-yogurt');
      expect(result.confidence, Confidence.medium);
    });

    test('unknown foods return low confidence with no match — never a '
        'silent wrong log', () {
      final result = parser.parse('mystery casserole').single;
      expect(result.matchedFoodId, isNull);
      expect(result.confidence, Confidence.low);
      expect(result.rawText, 'mystery casserole');
    });

    test('comma-separated lists split like "and"', () {
      final result = parser.parse('rice, milk');
      expect(result.map((c) => c.matchedFoodId), ['f-rice', 'f-milk']);
    });

    test('"half" is a fractional quantity', () {
      final result = parser.parse('half cup rice').single;
      expect(result.quantity, 0.5);
      expect(result.unit, 'cup');
    });

    test('empty and whitespace input parse to nothing', () {
      expect(parser.parse(''), isEmpty);
      expect(parser.parse('   '), isEmpty);
    });

    test('deterministic: same input, same output', () {
      expect(
        parser.parse('2 eggs and toast'),
        parser.parse('2 eggs and toast'),
      );
    });
  });
}
