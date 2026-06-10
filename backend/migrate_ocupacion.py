"""
migrate_ocupacion.py — Agrega el campo `ocupacion` a la tabla `users`.

Ejecutar UNA sola vez en bases de datos MySQL existentes:
    python migrate_ocupacion.py

En bases de datos nuevas (primer create_all) no es necesario,
el campo se crea automáticamente.
"""

import os
from sqlalchemy import create_engine, text

os.environ.setdefault("USE_MOCK_DB", "False")

from core.config import settings

engine = create_engine(settings.DATABASE_URL)

CHECK_SQL = """
SELECT COUNT(*) FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME   = 'users'
  AND COLUMN_NAME  = 'ocupacion';
"""

ALTER_SQL = """
ALTER TABLE users
ADD COLUMN ocupacion ENUM(
    'estudiante',
    'trabajador_dependiente',
    'trabajador_independiente',
    'emprendedor',
    'otro'
) NULL DEFAULT NULL;
"""

with engine.connect() as conn:
    exists = conn.execute(text(CHECK_SQL)).scalar()
    if exists:
        print("ℹ️  La columna `ocupacion` ya existe. No se realizaron cambios.")
    else:
        conn.execute(text(ALTER_SQL))
        conn.commit()
        print("✅ Columna `ocupacion` agregada a la tabla `users`.")
