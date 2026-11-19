"""
migrate_events_table_v2.py
─────────────────────────────────────────────────────────────────────────────
Run ONCE after deploying events_backend_updated.py.
Adds any missing columns to the events table so the updated GET/POST routes
work correctly.

Usage:
    python migrate_events_table_v2.py
"""

import sqlalchemy as sa
from database.db import engine


# Columns the updated backend now reads and writes.
# Format: (column_name, sql_definition)
COLUMNS_TO_ADD = [
    ("description",          "TEXT           DEFAULT ''"),
    ("type",                 "VARCHAR(30)    DEFAULT 'seminar'"),
    ("status",               "VARCHAR(20)    DEFAULT 'upcoming'"),
    ("start_date",           "TIMESTAMP      DEFAULT NULL"),
    ("end_date",             "TIMESTAMP      DEFAULT NULL"),
    ("venue",                "VARCHAR(255)   DEFAULT 'TBD'"),
    ("expected_attendees",   "INTEGER        DEFAULT 0"),
    ("organizer",            "VARCHAR(100)   DEFAULT 'BDO'"),
    ("is_virtual",           "BOOLEAN        DEFAULT FALSE"),
    ("meeting_link",         "TEXT           DEFAULT NULL"),
    ("predicted_attendees",  "INTEGER        DEFAULT NULL"),
]


def run_migration():
    with engine.connect() as conn:
        for col_name, col_def in COLUMNS_TO_ADD:
            try:
                conn.execute(
                    sa.text(
                        f"ALTER TABLE events "
                        f"ADD COLUMN IF NOT EXISTS {col_name} {col_def};"
                    )
                )
                print(f"  ✅  {col_name}")
            except Exception as e:
                print(f"  ⚠️  Skipped {col_name}: {e}")
        conn.commit()

    print("\n✅ Migration complete — all columns present.")


if __name__ == "__main__":
    run_migration()
