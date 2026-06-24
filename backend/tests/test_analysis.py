"""
tests/test_analysis.py — Tests del módulo de Análisis (rediseño 2026-06)

Cubre: resumen con comparativa al mes anterior, detalle de categoría
(total, %, comparativa) y desglose por comercio (incluido "Sin comercio").
"""

from datetime import date

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from db.models import Base, User, Expense
from core.enums import CategoriaGasto
from core.budgets import crear_presupuesto_mes
from core.analysis import (
    _mes_anterior,
    resumen_overview,
    detalle_categoria,
    desglose_por_comercio,
    SIN_COMERCIO,
)

engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)


@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    db.add(User(id=1, nombre="Test", email="analysis@test.com", hashed_password="..."))
    db.commit()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)


def _gasto(db, categoria, monto, mes, anio, comercio=None, dia=15):
    db.add(Expense(
        user_id=1,
        categoria=categoria,
        monto=monto,
        comercio=comercio,
        fecha=date(anio, mes, dia),
    ))


@pytest.fixture
def datos(db):
    """Siembra un escenario fijo en el mes actual y el anterior."""
    hoy = date.today()
    ma, aa = hoy.month, hoy.year
    mp, ap = _mes_anterior(ma, aa)

    # Mes actual — Comida: KFC 60+40=100 (2 tx), Metro 80 (1 tx), sin comercio 20 (1 tx)
    _gasto(db, CategoriaGasto.COMIDA, 60, ma, aa, comercio="KFC")
    _gasto(db, CategoriaGasto.COMIDA, 40, ma, aa, comercio="KFC")
    _gasto(db, CategoriaGasto.COMIDA, 80, ma, aa, comercio="Metro")
    _gasto(db, CategoriaGasto.COMIDA, 20, ma, aa, comercio=None)
    # Mes actual — Transporte: Uber 50
    _gasto(db, CategoriaGasto.TRANSPORTE, 50, ma, aa, comercio="Uber")

    # Mes anterior — Comida: 200
    _gasto(db, CategoriaGasto.COMIDA, 200, mp, ap, comercio="KFC")

    # Presupuestos: actual 3000, anterior 2000
    crear_presupuesto_mes(db, user_id=1, monto_base=3000, mes=ma, anio=aa)
    crear_presupuesto_mes(db, user_id=1, monto_base=2000, mes=mp, anio=ap)
    db.commit()
    return ma, aa


def test_desglose_por_comercio_ordenado_y_sin_comercio(db, datos):
    ma, aa = datos
    desglose = desglose_por_comercio(db, 1, CategoriaGasto.COMIDA, ma, aa)

    # KFC (100) > Metro (80) > Sin comercio (20), ordenado desc
    assert [d["comercio"] for d in desglose] == ["KFC", "Metro", SIN_COMERCIO]
    assert desglose[0]["total"] == 100.0
    assert desglose[0]["n_transacciones"] == 2  # las dos compras en KFC
    assert desglose[2]["comercio"] == SIN_COMERCIO
    assert desglose[2]["total"] == 20.0


def test_overview_con_comparativa_mes_anterior(db, datos):
    ma, aa = datos
    o = resumen_overview(db, 1, ma, aa)

    # Mes actual: gasto 200(comida)+50(transporte)=250, ingresos 3000, ahorro 2750
    assert o["gasto_total"] == 250.0
    assert o["ingresos"] == 3000.0
    assert o["ahorro"] == 2750.0
    # Mes anterior: gasto 200, ingresos 2000, ahorro 1800
    assert o["gasto_total_prev"] == 200.0
    assert o["ingresos_prev"] == 2000.0
    assert o["ahorro_prev"] == 1800.0


def test_detalle_categoria_total_porcentaje_y_comparativa(db, datos):
    ma, aa = datos
    d = detalle_categoria(db, 1, CategoriaGasto.COMIDA, ma, aa)

    assert d["categoria"] == "comida"
    assert d["total"] == 200.0          # comida del mes actual
    assert d["total_prev"] == 200.0     # comida del mes anterior
    assert d["porcentaje_del_total"] == 80.0  # 200 de 250
    assert len(d["desglose_comercio"]) == 3


def test_overview_sin_datos_devuelve_ceros(db):
    # Usuario sin gastos ni presupuesto en un mes lejano
    o = resumen_overview(db, 1, 1, 2000)
    assert o["gasto_total"] == 0.0
    assert o["ingresos"] == 0.0
    assert o["ahorro"] == 0.0
    assert o["gasto_total_prev"] == 0.0
