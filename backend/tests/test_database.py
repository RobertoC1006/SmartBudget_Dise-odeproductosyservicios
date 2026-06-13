import sqlite3
import pytest
from datetime import date
from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.exc import IntegrityError, PendingRollbackError

from db.models import Base, User, Budget, IncomeLog, Goal, Expense, Alert, SmartScoreSnapshot
from core.enums import CategoriaGasto, EstadoMeta, FuenteGasto, TipoAlerta

# ─── SQLite Foreign Key Enforcement ──────────────────────────────────────────
# SQLite no valida llaves foráneas por defecto. Esta directiva activa el soporte
# para que los tests de borrado en cascada (CASCADE) funcionen igual que en MySQL.
# Solo aplica a conexiones SQLite reales: el listener es global, así que sin este
# guard el PRAGMA se enviaría también a MySQL (al importar api.main en otros
# tests) y rompería con un error de sintaxis.
@event.listens_for(Engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    if not isinstance(dbapi_connection, sqlite3.Connection):
        return
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()

# Configuración del motor de pruebas local
engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)

@pytest.fixture
def db_session():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    
    # Crear un usuario inicial
    user = User(id=1, nombre="Test User", email="db_test@test.com", hashed_password="hashed_password")
    session.add(user)
    session.commit()
    
    yield session
    
    session.close()
    Base.metadata.drop_all(bind=engine)


# ════════════════════════════════════════════════════════════════════════════
# TESTS: RESTRICCIONES DE UNICIDAD (UniqueConstraint)
# ════════════════════════════════════════════════════════════════════════════

def test_user_email_unico(db_session):
    """Verifica que no se puedan crear dos usuarios con el mismo correo."""
    otro_usuario = User(nombre="Otro", email="db_test@test.com", hashed_password="pass")
    db_session.add(otro_usuario)
    with pytest.raises(IntegrityError):
        db_session.commit()

def test_presupuesto_unico_por_mes_anio(db_session):
    """Verifica que un usuario no pueda tener dos presupuestos en el mismo mes y año."""
    b1 = Budget(user_id=1, mes=6, anio=2026, monto_base=1000.0)
    db_session.add(b1)
    db_session.commit()

    b2 = Budget(user_id=1, mes=6, anio=2026, monto_base=500.0)
    db_session.add(b2)
    with pytest.raises(IntegrityError):
        db_session.commit()

def test_score_history_unico_por_mes_anio(db_session):
    """Verifica que un usuario no pueda tener dos snapshots de score en el mismo mes y año."""
    s1 = SmartScoreSnapshot(user_id=1, score=85, mes=6, anio=2026)
    db_session.add(s1)
    db_session.commit()

    s2 = SmartScoreSnapshot(user_id=1, score=90, mes=6, anio=2026)
    db_session.add(s2)
    with pytest.raises(IntegrityError):
        db_session.commit()


# ════════════════════════════════════════════════════════════════════════════
# TESTS: RESTRICCIONES DE INTEGRIDAD (CheckConstraint)
# ════════════════════════════════════════════════════════════════════════════

def test_budget_monto_base_positivo(db_session):
    """Verifica que no se puedan crear presupuestos con monto base negativo."""
    b = Budget(user_id=1, mes=6, anio=2026, monto_base=-100.0)
    db_session.add(b)
    with pytest.raises(IntegrityError):
        db_session.commit()

def test_income_log_monto_positivo(db_session):
    """Verifica que no se puedan crear ingresos adicionales menores o iguales a cero."""
    b = Budget(user_id=1, mes=6, anio=2026, monto_base=1000.0)
    db_session.add(b)
    db_session.commit()

    log_invalido = IncomeLog(budget_id=b.id, monto=-50.0, descripcion="Bono negativo")
    db_session.add(log_invalido)
    with pytest.raises(IntegrityError):
        db_session.commit()

def test_expense_monto_positivo(db_session):
    """Verifica que no se puedan registrar gastos menores o iguales a cero."""
    gasto = Expense(
        user_id=1,
        categoria=CategoriaGasto.COMIDA,
        monto=0.0,  # Inválido, debe ser > 0
        descripcion="Gasto cero",
        fecha=date(2026, 6, 5),
        fuente=FuenteGasto.MANUAL
    )
    db_session.add(gasto)
    with pytest.raises(IntegrityError):
        db_session.commit()

def test_goal_montos_positivos(db_session):
    """Verifica restricciones de saldo acumulado y monto objetivo en las metas."""
    # Caso 1: monto_objetivo inválido (<= 0)
    m1 = Goal(user_id=1, nombre="Auto", monto_objetivo=0.0, saldo_acumulado=0.0)
    db_session.add(m1)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()

    # Caso 2: saldo_acumulado negativo
    m2 = Goal(user_id=1, nombre="Auto", monto_objetivo=1000.0, saldo_acumulado=-5.0)
    db_session.add(m2)
    with pytest.raises(IntegrityError):
        db_session.commit()

def test_smart_score_snapshot_rango_score(db_session):
    """Verifica que el score esté siempre en el rango de 0 a 100."""
    # Caso 1: score superior a 100
    s1 = SmartScoreSnapshot(user_id=1, score=105, mes=6, anio=2026)
    db_session.add(s1)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()

    # Caso 2: score negativo
    s2 = SmartScoreSnapshot(user_id=1, score=-10, mes=6, anio=2026)
    db_session.add(s2)
    with pytest.raises(IntegrityError):
        db_session.commit()


# ════════════════════════════════════════════════════════════════════════════
# TESTS: BORRADO EN CASCADA FISICO (ondelete="CASCADE")
# ════════════════════════════════════════════════════════════════════════════

def test_cascade_delete_usuario(db_session):
    """Verifica que al eliminar un usuario se eliminen todos sus datos asociados en cascada."""
    # 1. Crear presupuesto, meta, gasto y alerta
    b = Budget(user_id=1, mes=6, anio=2026, monto_base=1000.0)
    db_session.add(b)
    
    g = Goal(user_id=1, nombre="Vacaciones", monto_objetivo=500.0)
    db_session.add(g)

    e = Expense(
        user_id=1,
        categoria=CategoriaGasto.COMIDA,
        monto=15.50,
        descripcion="Almuerzo",
        fecha=date(2026, 6, 5),
        fuente=FuenteGasto.MANUAL
    )
    db_session.add(e)

    a = Alert(user_id=1, titulo="Alerta", mensaje="Mensaje", tipo=TipoAlerta.INFORMATIVA)
    db_session.add(a)

    db_session.commit()

    # 2. Agregar un ingreso adicional para probar cascada multinivel (User -> Budget -> IncomeLog)
    log = IncomeLog(budget_id=b.id, monto=100.0, descripcion="Bono")
    db_session.add(log)
    db_session.commit()

    # 3. Eliminar al usuario
    user = db_session.query(User).filter(User.id == 1).first()
    db_session.delete(user)
    db_session.commit()

    # 4. Asegurar que las dependencias desaparecieron de la BD
    assert db_session.query(Budget).filter(Budget.user_id == 1).first() is None
    assert db_session.query(Goal).filter(Goal.user_id == 1).first() is None
    assert db_session.query(Expense).filter(Expense.user_id == 1).first() is None
    assert db_session.query(Alert).filter(Alert.user_id == 1).first() is None
    assert db_session.query(IncomeLog).filter(IncomeLog.budget_id == b.id).first() is None
