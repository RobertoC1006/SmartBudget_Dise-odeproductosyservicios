"""
tests/test_expenses_recent.py — "Actividad reciente" del Dashboard.

Verifica que listar_gastos_recientes ordena por cuándo se registró el gasto
(created_at desc), sin filtrar por mes: una boleta registrada tarde aparece
arriba aunque la compra sea de un mes anterior.
"""

from datetime import date, datetime

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from db.models import Base, User, Expense
from core.enums import CategoriaGasto
from core.expenses import listar_gastos_recientes

engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)


@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    db.add(User(id=1, nombre="Test", email="recent@test.com", hashed_password="..."))
    db.commit()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)


def _gasto(db, monto, fecha, created_at, comercio=None):
    db.add(Expense(
        user_id=1,
        categoria=CategoriaGasto.COMIDA,
        monto=monto,
        comercio=comercio,
        fecha=fecha,
        created_at=created_at,
    ))


def test_recientes_ordena_por_registro_no_por_fecha(db):
    # Compra de mayo pero registrada hoy (created_at es el más reciente).
    _gasto(db, 1200, date(2026, 5, 9), datetime(2026, 6, 24, 10, 0), comercio="Backfill")
    # Compras de junio registradas antes.
    _gasto(db, 10, date(2026, 6, 20), datetime(2026, 6, 22, 9, 0), comercio="Cena")
    _gasto(db, 145.90, date(2026, 6, 15), datetime(2026, 6, 16, 9, 0), comercio="El Hornero")
    db.commit()

    recientes = listar_gastos_recientes(db, 1, limite=5)

    # La boleta registrada al final (mayo) va arriba pese a tener la fecha de compra más antigua.
    assert [g.comercio for g in recientes] == ["Backfill", "Cena", "El Hornero"]


def test_recientes_respeta_limite(db):
    for i in range(8):
        _gasto(db, 10 + i, date(2026, 6, 1), datetime(2026, 6, 1, 0, i))
    db.commit()

    assert len(listar_gastos_recientes(db, 1, limite=5)) == 5
