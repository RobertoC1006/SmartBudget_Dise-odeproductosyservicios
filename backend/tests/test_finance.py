"""
tests/test_finance.py — Tests de lógica financiera (Budgets + Goals)
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from db.models import Base, User
from core.budgets import crear_presupuesto_mes, agregar_ingreso_adicional, calcular_resumen_mensual
from core.goals import crear_meta, aportar_a_meta
from core.exceptions import SaldoInsuficienteError

# Setup de BD en memoria para tests
engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)

@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    # Crear usuario de prueba
    user = User(id=1, nombre="Test", email="test@test.com", hashed_password="...")
    db.add(user)
    db.commit()
    yield db
    db.close()
    Base.metadata.drop_all(bind=engine)

def test_flujo_presupuesto_y_ahorro(db):
    from datetime import date
    hoy = date.today()
    # 1. Crear presupuesto de 2000 soles para el mes corriente
    crear_presupuesto_mes(db, user_id=1, monto_base=2000, mes=hoy.month, anio=hoy.year)
    resumen = calcular_resumen_mensual(db, user_id=1)
    assert resumen["saldo_disponible"] == 2000

    # 2. Agregar ingreso extra de 500
    agregar_ingreso_adicional(db, user_id=1, monto=500, descripcion="Bono")
    resumen = calcular_resumen_mensual(db, user_id=1)
    assert resumen["saldo_disponible"] == 2500

    # 3. Crear meta de 1000 y aportar 400
    meta = crear_meta(db, user_id=1, nombre="Bici", monto_obj=1000)
    aportar_a_meta(db, user_id=1, goal_id=meta.id, monto=400)
    
    # 4. Verificar que el saldo disponible BAJÓ (dinero reservado)
    resumen = calcular_resumen_mensual(db, user_id=1)
    assert resumen["saldo_disponible"] == 2100 # 2500 - 400
    
    # 5. Intentar aportar más de lo que hay
    with pytest.raises(SaldoInsuficienteError):
        aportar_a_meta(db, user_id=1, goal_id=meta.id, monto=3000)
