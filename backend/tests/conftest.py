"""
tests/conftest.py — Configuración global de pytest para SmartBudget+

conftest.py es el archivo de configuración de pytest. Se ejecuta automáticamente
antes de cualquier test. Aquí definimos:
- Fixtures compartidas (objetos reutilizables entre tests)
- Configuración del entorno de testing
- Variables de entorno para testing (sin necesitar el .env.docker real)
"""

import os
import pytest

# ─── Variables de entorno para testing ──────────────────────────────────────
# Establecemos las variables ANTES de importar cualquier módulo de la app.
# Esto es necesario porque config.py lee las variables al importarse.
# En testing no queremos depender del .env.docker real.
os.environ.setdefault("JWT_SECRET_KEY", "clave_secreta_para_testing_no_usar_en_produccion_32chars")
os.environ.setdefault("OPENAI_API_KEY", "sk-test-fake-key-for-testing")
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")  # BD en memoria para tests
