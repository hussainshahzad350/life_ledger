import 'package:life_ledger/core/database/migrations/migration.dart';
import 'package:sqflite/sqflite.dart';

/// Schema v1 — the initial LifeLedger schema (docs/04-database-design.md §4–§6).
///
/// Creates every table with the standard audit/sync columns (docs/04 §2.1),
/// domain `CHECK` constraints (docs/04 §11), the hot-path indexes (docs/04 §6),
/// and seeds the `symptom_type` lookup.
class V1Initial implements Migration {
  /// Creates the v1 migration.
  const V1Initial();

  @override
  int get version => 1;

  @override
  String get description =>
      'Initial schema: profile, versioned goals, food catalog + entries, '
      'water/weight/sleep/mood/symptom/exercise logs, insights, app_meta, '
      'indexes, symptom_type seed.';

  /// Standard audit/sync columns appended to every user-data table
  /// (docs/04 §2.1). UUID `id` is declared per-table as the primary key.
  static const String _auditColumns = '''
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
    sync_status TEXT NOT NULL DEFAULT 'local'
      CHECK (sync_status IN ('local', 'pending', 'synced', 'conflict'))''';

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        display_name TEXT,
        sex TEXT CHECK (sex IN ('male', 'female', 'unspecified')),
        birth_date INTEGER,
        height_cm REAL CHECK (height_cm > 0 AND height_cm < 300),
        unit_system TEXT NOT NULL DEFAULT 'metric'
          CHECK (unit_system IN ('metric', 'imperial')),
        activity_level TEXT CHECK (activity_level IN
          ('sedentary', 'light', 'moderate', 'active', 'very_active')),
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE goal (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        type TEXT NOT NULL CHECK (type IN
          ('calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar',
           'water', 'weight', 'sleep')),
        target_value REAL NOT NULL,
        source TEXT NOT NULL CHECK (source IN ('system', 'user')),
        objective TEXT CHECK (objective IN ('maintain', 'lose', 'gain')),
        effective_from INTEGER NOT NULL,
        effective_to INTEGER,
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE food_item (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0 CHECK (is_custom IN (0, 1)),
        is_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0, 1)),
        serving_size REAL NOT NULL CHECK (serving_size > 0),
        serving_unit TEXT NOT NULL,
        calories REAL NOT NULL CHECK (calories >= 0),
        protein_g REAL NOT NULL CHECK (protein_g >= 0),
        carbs_g REAL NOT NULL CHECK (carbs_g >= 0),
        fat_g REAL NOT NULL CHECK (fat_g >= 0),
        fiber_g REAL NOT NULL CHECK (fiber_g >= 0),
        sugar_g REAL NOT NULL CHECK (sugar_g >= 0),
        source_ref TEXT,
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE food_entry (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        food_item_id TEXT NOT NULL REFERENCES food_item(id),
        logged_at INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        meal_slot TEXT NOT NULL CHECK (meal_slot IN
          ('breakfast', 'lunch', 'dinner', 'snack')),
        quantity REAL NOT NULL CHECK (quantity > 0),
        note TEXT,
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE water_entry (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        logged_at INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        amount_ml REAL NOT NULL CHECK (amount_ml > 0),
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_entry (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        logged_at INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        weight_kg REAL NOT NULL CHECK (weight_kg > 0 AND weight_kg < 700),
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE sleep_entry (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        logged_at INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        start_at INTEGER,
        end_at INTEGER,
        duration_min INTEGER NOT NULL CHECK (duration_min >= 0),
        quality INTEGER CHECK (quality BETWEEN 1 AND 5),
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE mood_entry (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        logged_at INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        mood INTEGER NOT NULL CHECK (mood BETWEEN 1 AND 5),
        note TEXT,
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE symptom_type (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0 CHECK (is_custom IN (0, 1)),
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE symptom_entry (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        symptom_type_id TEXT NOT NULL REFERENCES symptom_type(id),
        logged_at INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        severity INTEGER NOT NULL CHECK (severity BETWEEN 1 AND 5),
        note TEXT,
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_entry (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        logged_at INTEGER NOT NULL,
        local_date TEXT NOT NULL,
        activity TEXT NOT NULL,
        duration_min INTEGER NOT NULL CHECK (duration_min >= 0),
        intensity TEXT CHECK (intensity IN ('light', 'moderate', 'vigorous')),
        energy_kcal REAL CHECK (energy_kcal >= 0),
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE insight (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES user_profile(id),
        rule_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        confidence TEXT NOT NULL CHECK (confidence IN ('low', 'medium', 'high')),
        evidence_json TEXT,
        period_start INTEGER NOT NULL,
        period_end INTEGER NOT NULL,
        feedback TEXT CHECK (feedback IN ('helpful', 'unhelpful')),
        dismissed INTEGER NOT NULL DEFAULT 0 CHECK (dismissed IN (0, 1)),
        $_auditColumns
      )
    ''');

    await db.execute('''
      CREATE TABLE app_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Hot-path indexes (docs/04 §6).
    await db.execute(
      'CREATE INDEX idx_food_entry_user_date '
      'ON food_entry (user_id, local_date, is_deleted)',
    );
    await db.execute(
      'CREATE INDEX idx_food_entry_logged '
      'ON food_entry (user_id, logged_at)',
    );
    await db.execute(
      'CREATE INDEX idx_water_user_date '
      'ON water_entry (user_id, local_date, is_deleted)',
    );
    await db.execute(
      'CREATE INDEX idx_weight_user_date '
      'ON weight_entry (user_id, local_date)',
    );
    await db.execute(
      'CREATE INDEX idx_sleep_user_date '
      'ON sleep_entry (user_id, local_date)',
    );
    await db.execute(
      'CREATE INDEX idx_mood_user_date '
      'ON mood_entry (user_id, local_date)',
    );
    await db.execute(
      'CREATE INDEX idx_symptom_user_date '
      'ON symptom_entry (user_id, local_date)',
    );
    await db.execute(
      'CREATE INDEX idx_exercise_user_date '
      'ON exercise_entry (user_id, local_date)',
    );
    await db.execute(
      'CREATE INDEX idx_goal_user_type_active '
      'ON goal (user_id, type, effective_to)',
    );
    await db.execute('CREATE INDEX idx_food_item_name ON food_item (name)');
    await db.execute(
      'CREATE INDEX idx_insight_user_period '
      'ON insight (user_id, period_end, dismissed)',
    );

    // Seed common symptom types (docs/04 §4.6). Fixed ids keep the seed
    // idempotent and stable across installs.
    const seedTime =
        0; // epoch — marks rows as installer-seeded, not user data.
    const seedSymptoms = <(String, String)>[
      ('st-bloating', 'Bloating'),
      ('st-headache', 'Headache'),
      ('st-fatigue', 'Fatigue'),
      ('st-nausea', 'Nausea'),
      ('st-stomach-pain', 'Stomach pain'),
      ('st-heartburn', 'Heartburn'),
      ('st-constipation', 'Constipation'),
      ('st-diarrhea', 'Diarrhea'),
      ('st-low-energy', 'Low energy'),
    ];
    for (final (id, name) in seedSymptoms) {
      await db.insert('symptom_type', <String, Object?>{
        'id': id,
        'name': name,
        'is_custom': 0,
        'created_at': seedTime,
        'updated_at': seedTime,
      });
    }
  }
}
