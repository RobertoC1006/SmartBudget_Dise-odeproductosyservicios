"""
tests/test_goals_redesign.py — Tests de la Fase 0 del rediseño de metas

Cubre: persistencia de fecha_limite y recordatorio, historial de aportes
(goal_contributions), edición de meta, cascade al eliminar y el SmartScore
graduado por progreso de metas.
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
    editar_meta,
    listar_aportes,
    eliminar_meta,
    listar_metas_con_progreso,
)
from core.smartscore import calcular_score_con_desglose
from core.enums import EstadoMeta, CategoriaMeta

engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)


@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    session.add(User(id=1, nombre="Test", email="meta@test.com", hashed_password="..."))
    session.commit()
    yield session
    session.close()
    Base.metadata.drop_all(bind=engine)


def _budget(db, monto=2000):
    hoy = date.today()
    crear_presupuesto_mes(db, user_id=1, monto_base=monto, mes=hoy.month, anio=hoy.year)


def test_crear_meta_persiste_fecha_recordatorio_y_categoria(db):
    objetivo = date(2026, 12, 5)
    meta = crear_meta(
        db, 1, "Viaje a Cusco", 3000,
        fecha_lim=objetivo,
        categoria=CategoriaMeta.VIAJE,
        recordatorio=True,
    )
    assert meta.fecha_limite == objetivo
    assert meta.recordatorio is True
    assert meta.categoria == "viaje"

    # listar_metas_con_progreso expone los campos para Flutter
    fila = listar_metas_con_progreso(db, 1)[0]
    assert fila["recordatorio"] is True
    assert fila["fecha_limite"] == "2026-12-05"
    assert fila["categoria"] == "viaje"


def test_crear_meta_categoria_por_defecto_otros(db):
    meta = crear_meta(db, 1, "Algo sin categoría", 500)
    assert meta.categoria == "otros"


def test_aporte_registra_historial_ordenado(db):
    _budget(db)
    meta = crear_meta(db, 1, "Laptop", 3500)
    aportar_a_meta(db, 1, meta.id, 100)
    aportar_a_meta(db, 1, meta.id, 250)

    aportes = listar_aportes(db, 1, meta.id)
    assert len(aportes) == 2
    assert [a["monto"] for a in aportes] == [100, 250]  # del más antiguo al más reciente

    # La suma de aportes cuadra con el saldo acumulado
    assert sum(a["monto"] for a in aportes) == meta.saldo_acumulado


def test_eliminar_meta_borra_aportes_en_cascada(db):
    _budget(db)
    meta = crear_meta(db, 1, "Auto", 10000)
    aportar_a_meta(db, 1, meta.id, 300)
    assert db.query(GoalContribution).count() == 1

    eliminar_meta(db, 1, meta.id)
    assert db.query(GoalContribution).count() == 0


def test_editar_meta_actualiza_campos_y_recalcula_estado(db):
    _budget(db)
    meta = crear_meta(db, 1, "Curso", 2000)
    aportar_a_meta(db, 1, meta.id, 800)  # 40% -> EN_PROGRESO

    # Bajar el objetivo por debajo del saldo acumulado -> COMPLETADA
    editada = editar_meta(db, 1, meta.id, monto_obj=500, nombre="Curso intensivo")
    assert editada.nombre == "Curso intensivo"
    assert editada.estado == EstadoMeta.COMPLETADA

    # Subir el objetivo de nuevo -> vuelve a EN_PROGRESO
    reabierta = editar_meta(db, 1, meta.id, monto_obj=2000)
    assert reabierta.estado == EstadoMeta.EN_PROGRESO


def test_smartscore_metas_graduado(db):
    _budget(db)

    # Sin metas: el criterio de metas aporta 0
    assert calcular_score_con_desglose(db, 1)["desglose"]["metas"] == 0

    # Meta al 50%: 10 base + 20*0.5 = 20
    meta = crear_meta(db, 1, "Meta", 1000)
    aportar_a_meta(db, 1, meta.id, 500)
    assert calcular_score_con_desglose(db, 1)["desglose"]["metas"] == 20

    # Meta completada: 10 base + 20*1.0 = 30
    aportar_a_meta(db, 1, meta.id, 500)
    assert meta.estado == EstadoMeta.COMPLETADA
    assert calcular_score_con_desglose(db, 1)["desglose"]["metas"] == 30


def test_contribute_sube_el_score(db):
    _budget(db)
    meta = crear_meta(db, 1, "Meta", 1000)

    score_antes = calcular_score_con_desglose(db, 1)["score"]
    aportar_a_meta(db, 1, meta.id, 500)
    score_despues = calcular_score_con_desglose(db, 1)["score"]

    assert score_despues > score_antes
