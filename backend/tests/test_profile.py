"""
tests/test_profile.py — Tests del resumen de perfil (rediseño de Perfil, 2026-06)

Cubre las métricas reales del "Resumen personal" de la pantalla 1A:
metas activas, gastos registrados, dinero ahorrado y SmartScore (defensivo).
"""

from datetime import date

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from db.models import Base, User, Goal, Expense
from core.enums import CategoriaGasto, EstadoMeta
from core.budgets import crear_presupuesto_mes
from core.profile import obtener_resumen_perfil

engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)


@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    db.add(User(id=1, nombre="Test", email="profile@test.com", hashed_password="..."))
    db.commit()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)


def test_metas_activas_excluye_completadas_y_canceladas(db):
    db.add_all([
        Goal(user_id=1, nombre="Viaje", monto_objetivo=1000, saldo_acumulado=300,
             estado=EstadoMeta.EN_PROGRESO),
        Goal(user_id=1, nombre="Laptop", monto_objetivo=2000, saldo_acumulado=0,
             estado=EstadoMeta.PENDIENTE),
        Goal(user_id=1, nombre="Hecha", monto_objetivo=500, saldo_acumulado=500,
             estado=EstadoMeta.COMPLETADA),
        Goal(user_id=1, nombre="Abandonada", monto_objetivo=800, saldo_acumulado=0,
             estado=EstadoMeta.CANCELADA),
    ])
    db.commit()

    r = obtener_resumen_perfil(db, 1)
    # Solo pendiente + en_progreso cuentan como activas.
    assert r["metas_activas"] == 2


def test_dinero_ahorrado_suma_todas_las_metas(db):
    db.add_all([
        Goal(user_id=1, nombre="A", monto_objetivo=1000, saldo_acumulado=300,
             estado=EstadoMeta.EN_PROGRESO),
        Goal(user_id=1, nombre="B", monto_objetivo=500, saldo_acumulado=500,
             estado=EstadoMeta.COMPLETADA),
        Goal(user_id=1, nombre="C", monto_objetivo=2000, saldo_acumulado=0,
             estado=EstadoMeta.PENDIENTE),
    ])
    db.commit()

    r = obtener_resumen_perfil(db, 1)
    # Incluye el saldo de la meta completada (dinero efectivamente ahorrado).
    assert r["dinero_ahorrado"] == 800.0


def test_cuenta_gastos_registrados(db):
    db.add_all([
        Expense(user_id=1, categoria=CategoriaGasto.COMIDA, monto=20, fecha=date(2026, 1, 5)),
        Expense(user_id=1, categoria=CategoriaGasto.TRANSPORTE, monto=15, fecha=date(2026, 2, 8)),
        Expense(user_id=1, categoria=CategoriaGasto.OCIO, monto=40, fecha=date(2026, 3, 1)),
    ])
    db.commit()

    r = obtener_resumen_perfil(db, 1)
    assert r["gastos_registrados"] == 3


def test_sin_presupuesto_smartscore_es_none_y_no_rompe(db):
    r = obtener_resumen_perfil(db, 1)
    assert r["smartscore"] is None
    assert r["smartscore_delta"] == 0
    assert r["metas_activas"] == 0
    assert r["gastos_registrados"] == 0
    assert r["dinero_ahorrado"] == 0.0


def test_con_presupuesto_calcula_smartscore(db):
    hoy = date.today()
    crear_presupuesto_mes(db, user_id=1, monto_base=3000, mes=hoy.month, anio=hoy.year)
    db.commit()

    r = obtener_resumen_perfil(db, 1)
    assert r["smartscore"] is not None
    assert 0 <= r["smartscore"] <= 100
