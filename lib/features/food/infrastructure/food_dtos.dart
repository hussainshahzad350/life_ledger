import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';

/// Row ↔ entity mapping for `food_item` and `food_entry` (docs/09 dtos).
abstract final class FoodDtos {
  /// Builds a [FoodItem] from a `food_item` row.
  static FoodItem itemFromRow(Map<String, Object?> row) => FoodItem(
    id: row['id']! as String,
    name: row['name']! as String,
    brand: row['brand'] as String?,
    isCustom: (row['is_custom']! as int) == 1,
    isFavorite: (row['is_favorite']! as int) == 1,
    servingSize: (row['serving_size']! as num).toDouble(),
    servingUnit: row['serving_unit']! as String,
    sourceRef: row['source_ref'] as String?,
    nutrition: Nutrition(
      calories: (row['calories']! as num).toDouble(),
      proteinG: (row['protein_g']! as num).toDouble(),
      carbsG: (row['carbs_g']! as num).toDouble(),
      fatG: (row['fat_g']! as num).toDouble(),
      fiberG: (row['fiber_g']! as num).toDouble(),
      sugarG: (row['sugar_g']! as num).toDouble(),
    ),
  );

  /// Builds a `food_item` row map from a [FoodItem].
  static Map<String, Object?> itemToRow(
    FoodItem item, {
    required int now,
    int? createdAt,
  }) => <String, Object?>{
    'id': item.id,
    'name': item.name,
    'brand': item.brand,
    'is_custom': item.isCustom ? 1 : 0,
    'is_favorite': item.isFavorite ? 1 : 0,
    'serving_size': item.servingSize,
    'serving_unit': item.servingUnit,
    'calories': item.nutrition.calories,
    'protein_g': item.nutrition.proteinG,
    'carbs_g': item.nutrition.carbsG,
    'fat_g': item.nutrition.fatG,
    'fiber_g': item.nutrition.fiberG,
    'sugar_g': item.nutrition.sugarG,
    'source_ref': item.sourceRef,
    'created_at': createdAt ?? now,
    'updated_at': now,
  };

  /// The SELECT column list joining an entry to its food item with
  /// unambiguous aliases (both tables have `id`, etc.). Pair with
  /// [entryFromJoinedRow].
  static const String joinedEntryColumns = '''
    fe.id           AS entry_id,
    fe.user_id      AS user_id,
    fe.quantity     AS quantity,
    fe.meal_slot    AS meal_slot,
    fe.logged_at    AS logged_at,
    fe.local_date   AS local_date,
    fe.note         AS note,
    fi.id           AS id,
    fi.name         AS name,
    fi.brand        AS brand,
    fi.is_custom    AS is_custom,
    fi.is_favorite  AS is_favorite,
    fi.serving_size AS serving_size,
    fi.serving_unit AS serving_unit,
    fi.calories     AS calories,
    fi.protein_g    AS protein_g,
    fi.carbs_g      AS carbs_g,
    fi.fat_g        AS fat_g,
    fi.fiber_g      AS fiber_g,
    fi.sugar_g      AS sugar_g,
    fi.source_ref   AS source_ref''';

  /// Builds a [FoodEntry] from a row produced with [joinedEntryColumns].
  static FoodEntry entryFromJoinedRow(Map<String, Object?> row) => FoodEntry(
    id: row['entry_id']! as String,
    userId: row['user_id']! as String,
    quantity: (row['quantity']! as num).toDouble(),
    mealSlot: MealSlot.values.byName(row['meal_slot']! as String),
    loggedAt: DateTime.fromMillisecondsSinceEpoch(
      row['logged_at']! as int,
      isUtc: true,
    ),
    localDate: row['local_date']! as String,
    note: row['note'] as String?,
    item: itemFromRow(row),
  );
}
