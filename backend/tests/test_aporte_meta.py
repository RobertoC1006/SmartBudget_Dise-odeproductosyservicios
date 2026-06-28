"""
tests/test_aporte_meta.py — Rediseño del flujo de aporte a meta (Fase 0)

Cubre: persistencia de fecha + descripción del aporte, fecha por defecto = hoy,
y el preview del impacto en SmartScore (delta real que NO se persiste).
"""

from datetime import date

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from db.models import Base, User, GoalContribution
from core.budgets import crear_presupuesto_mes
from core.goals import (
    crear_meta,
    aportar_a_meta,
    listar_aportes,
    previsualizar_impacto_aporte,
)
from core.exceptions import SaldoInsuficienteError

engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)


@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    session.add(User(id=1, nombre="Test", email="aporte@test.com", hashed_password="..."))
    session.commit()
    yield session
    session.close()
    Base.metadata.drop_all(bind=engine)


def _budget(db, monto=2000):
    hoy = date.today()
    crear_presupuesto_mes(db, user_id=1, monto_base=monto, mes=hoy.month, anio=hoy.year)


def test_aporte_persiste_fecha_y_descripcion(db):
    _budget(db)
    meta = crear_meta(db, 1, "Laptop", 3500)
    aportar_a_meta(db, 1, meta.id, 100, fecha=date(2026, 6, 5), descripcion="Aporte de mi sueldo")

    aportes = listar_aportes(db, 1, meta.id)
    assert len(aportes) == 1
    assert aportes[0]["fecha"] == "2026-06-05"
    assert aportes[0]["descripcion"] == "Aporte de mi sueldo"


def test_aporte_fecha_por_defecto_es_hoy(db):
    _budget(db)
    meta = crear_meta(db, 1, "Meta", 1000)
    aportar_a_meta(db, 1, meta.id, 200)  # sin fecha ni descripción

    aportes = listar_aportes(db, 1, meta.id)
    assert aportes[0]["fecha"] == date.today().isoformat()
    assert aportes[0]["descripcion"] is None


def test_preview_devuelve_delta_y_no_persiste(db):
    _budget(db, monto=2000)
    meta = crear_meta(db, 1, "Meta", 1000)

    saldo_antes = meta.saldo_acumulado
    n_aportes_antes = db.query(GoalContribution).count()

    preview = previsualizar_impacto_aporte(db, 1, meta.id, 500)

    # El delta es coherente y positivo (el aporte sube el criterio de metas)
    assert preview["score_nuevo"] == preview["score_anterior"] + preview["score_delta"]
    assert preview["score_delta"] > 0
    assert preview["completaria"] is False

    # Nada se persistió: ni el saldo de la meta ni un registro de aporte
    db.refresh(meta)
    assert meta.saldo_acumulado == saldo_antes
    assert db.query(GoalContribution).count() == n_aportes_antes


def test_preview_detecta_que_completaria(db):
    _budget(db, monto=2000)
    meta = crear_meta(db, 1, "Meta", 500)
    preview = previsualizar_impacto_aporte(db, 1, meta.id, 500)
    assert preview["completaria"] is True


def test_preview_saldo_insuficiente_falla(db):
    _budget(db, monto=100)
    meta = crear_meta(db, 1, "Meta", 1000)
    with pytest.raises(SaldoInsuficienteError):
        previsualizar_impacto_aporte(db, 1, meta.id, 500)
