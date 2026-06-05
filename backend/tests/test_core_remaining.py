"""
tests/test_core_remaining.py — Tests unitarios para expenses, simulator, smart_alerts y smartscore
"""

import pytest
from datetime import date, datetime
from unittest.mock import patch
from sqlalchemy import create_engine, and_
from sqlalchemy.orm import sessionmaker

from db.models import Base, User, Budget, Goal, Expense, Alert, SmartScoreSnapshot
from core.enums import CategoriaGasto, EstadoMeta, FuenteGasto, TipoAlerta
from core.exceptions import SaldoInsuficienteError, GastoNoEncontradoError
from core.budgets import crear_presupuesto_mes
from core.goals import crear_meta
from core.expenses import registrar_gasto, eliminar_gasto, listar_gastos_mes, calcular_gastos_por_categoria
from core.simulator import simular_compra
from core.smart_alerts import generar_alertas_usuario, obtener_alertas_priorizadas
from core.smartscore import calcular_score, guardar_snapshot, obtener_historial_score

# Setup de BD en memoria para tests
engine = create_engine("sqlite:///:memory:")
TestingSessionLocal = sessionmaker(bind=engine)

@pytest.fixture
def db():
    Base.metadata.create_all(bind=engine)
    session = TestingSessionLocal()
    # Crear usuario de prueba
    user = User(id=1, nombre="Test User", email="test@test.com", hashed_password="...")
    session.add(user)
    session.commit()
    yield session
    session.close()
    Base.metadata.drop_all(bind=engine)


# ════════════════════════════════════════════════════════════════════════════
# SECCIÓN 1: Tests de core/expenses.py
# ════════════════════════════════════════════════════════════════════════════

class TestExpenses:
    """Pruebas para el registro y gestión de gastos."""

    def test_registrar_gasto_exito(self, db):
        # 1. Arrange: Crear presupuesto para el mes corriente
        hoy = date.today()
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        
        # 2. Act: Registrar gasto de S/. 200 en COMIDA
        gasto = registrar_gasto(
            db, 
            user_id=1, 
            categoria=CategoriaGasto.COMIDA, 
            monto=200.0, 
            descripcion="Supermercado", 
            comercio="Plaza Vea", 
            fecha=date(hoy.year, hoy.month, 10)
        )
        
        # 3. Assert
        assert gasto.id is not None
        assert gasto.monto == 200.0
        assert gasto.categoria == CategoriaGasto.COMIDA
        
        # Verificar descuento del presupuesto
        budget = db.query(Budget).filter(Budget.user_id == 1).first()
        assert budget.saldo_disponible == 800.0
        assert budget.total_gastado == 200.0

    def test_registrar_gasto_saldo_insuficiente(self, db):
        # 1. Arrange
        hoy = date.today()
        crear_presupuesto_mes(db, user_id=1, monto_base=100, mes=hoy.month, anio=hoy.year)
        
        # 2. Act & Assert: Intentar gastar S/. 150
        with pytest.raises(SaldoInsuficienteError):
            registrar_gasto(
                db, 
                user_id=1, 
                categoria=CategoriaGasto.OTROS, 
                monto=150.0, 
                descripcion="Gasto extra", 
                comercio=None, 
                fecha=date(hoy.year, hoy.month, 10)
            )

    def test_eliminar_gasto_exito(self, db):
        # 1. Arrange
        hoy = date.today()
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        gasto = registrar_gasto(db, user_id=1, categoria=CategoriaGasto.TRANSPORTE, monto=50.0, descripcion="Taxi", comercio=None, fecha=date(hoy.year, hoy.month, 10))
        
        # 2. Act
        eliminar_gasto(db, user_id=1, expense_id=gasto.id)
        
        # 3. Assert: Verificar que no existe el gasto y el presupuesto se revirtió
        gasto_db = db.query(Expense).filter(Expense.id == gasto.id).first()
        assert gasto_db is None
        
        budget = db.query(Budget).filter(Budget.user_id == 1).first()
        assert budget.saldo_disponible == 1000.0
        assert budget.total_gastado == 0.0

    def test_eliminar_gasto_no_existe(self, db):
        # Act & Assert
        with pytest.raises(GastoNoEncontradoError):
            eliminar_gasto(db, user_id=1, expense_id=999)

    def test_listar_gastos_mes(self, db):
        # Arrange
        hoy = date.today()
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.COMIDA, monto=50.0, descripcion="Almuerzo", comercio=None, fecha=date(hoy.year, hoy.month, 10))
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.OCIO, monto=120.0, descripcion="Cine", comercio=None, fecha=date(hoy.year, hoy.month, 15))
        
        # Gasto de otro mes (anterior)
        if hoy.month == 1:
            m_prev, a_prev = 12, hoy.year - 1
        else:
            m_prev, a_prev = hoy.month - 1, hoy.year
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=m_prev, anio=a_prev)
        
        # Agregamos gasto del mes anterior directamente en BD para no chocar con checks de presupuesto activo
        db.add(Expense(user_id=1, categoria=CategoriaGasto.SALUD, monto=80.0, descripcion="Medicinas", comercio=None, fecha=date(a_prev, m_prev, 1), fuente=FuenteGasto.MANUAL))
        db.commit()
        
        # Act: Listar gastos de este mes
        gastos_este_mes = listar_gastos_mes(db, user_id=1, mes=hoy.month, anio=hoy.year)
        
        # Assert
        assert len(gastos_este_mes) == 2
        assert gastos_este_mes[0].monto == 120.0 # orden descendente de fecha
        assert gastos_este_mes[1].monto == 50.0

    def test_calcular_gastos_por_categoria(self, db):
        # Arrange
        hoy = date.today()
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.COMIDA, monto=50.0, descripcion="Almuerzo", comercio=None, fecha=date(hoy.year, hoy.month, 10))
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.COMIDA, monto=30.0, descripcion="Cena", comercio=None, fecha=date(hoy.year, hoy.month, 12))
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.OCIO, monto=150.0, descripcion="Cine", comercio=None, fecha=date(hoy.year, hoy.month, 15))
        
        # Act
        resumen = calcular_gastos_por_categoria(db, user_id=1, mes=hoy.month, anio=hoy.year)
        
        # Assert
        assert resumen["comida"] == 80.0
        assert resumen["ocio"] == 150.0
        assert "transporte" not in resumen


# ════════════════════════════════════════════════════════════════════════════
# SECCIÓN 2: Tests de core/simulator.py
# ════════════════════════════════════════════════════════════════════════════

class TestSimulator:
    """Pruebas para el simulador de compras inteligente (stateless)."""

    def test_simular_compra_viable_segura(self):
        # Arrange
        saldo_disponible = 1000.0
        monto_compra = 100.0 # 10% del disponible
        metas = []

        # Act
        res = simular_compra(saldo_disponible, monto_compra, metas)

        # Assert
        assert res["compra_viable"] is True
        assert res["saldo_proyectado"] == 900.0
        assert res["porcentaje_saldo_consumido"] == 10.0
        assert res["nivel_riesgo"] == "bajo"

    def test_simular_compra_viable_riesgo_medio(self):
        # Arrange
        saldo_disponible = 1000.0
        monto_compra = 500.0 # 50% del disponible
        metas = []

        # Act
        res = simular_compra(saldo_disponible, monto_compra, metas)

        # Assert
        assert res["compra_viable"] is True
        assert res["nivel_riesgo"] == "medio"

    def test_simular_compra_viable_riesgo_critico(self):
        # Arrange
        saldo_disponible = 1000.0
        monto_compra = 800.0 # 80% del disponible
        metas = []

        # Act
        res = simular_compra(saldo_disponible, monto_compra, metas)

        # Assert
        assert res["compra_viable"] is True
        assert res["nivel_riesgo"] == "critico"

    def test_simular_compra_inviable(self):
        # Arrange
        saldo_disponible = 1000.0
        monto_compra = 1200.0 # Más del disponible

        # Act
        res = simular_compra(saldo_disponible, monto_compra, [])

        # Assert
        assert res["compra_viable"] is False
        assert res["nivel_riesgo"] == "critico"
        assert res["saldo_proyectado"] == -200.0

    def test_simular_compra_impacto_metas(self):
        # Arrange
        saldo_disponible = 1000.0
        monto_compra = 400.0
        metas = [
            {"nombre": "Bicicleta", "monto_objetivo": 1000.0, "saldo_acumulado": 200.0, "faltante": 800.0}
        ]

        # Act
        res = simular_compra(saldo_disponible, monto_compra, metas)

        # Assert
        assert res["compra_viable"] is True
        assert len(res["impacto_metas"]) == 1
        assert res["impacto_metas"][0]["nombre"] == "Bicicleta"
        # 400 gastado / 800 faltante = 50% comprometido
        assert res["impacto_metas"][0]["porcentaje_comprometido"] == 50.0


# ════════════════════════════════════════════════════════════════════════════
# SECCIÓN 3: Tests de core/smart_alerts.py
# ════════════════════════════════════════════════════════════════════════════

class TestSmartAlerts:
    """Pruebas para las alertas inteligentes."""

    @patch("core.smart_alerts.date")
    def test_regla_advertencia_presupuesto_alto(self, mock_date, db):
        hoy = date.today()
        # 1. Arrange: Forzar día 10 (antes del día 20) y gasto de 85%
        mock_date.today.return_value = date(hoy.year, hoy.month, 10)
        mock_date.side_effect = lambda *args, **kw: date(*args, **kw) # Permitir llamadas directas a constructor
        
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.COMIDA, monto=850.0, descripcion="Compra grande", comercio=None, fecha=date(hoy.year, hoy.month, 10))

        # 2. Act: Generar alertas
        generar_alertas_usuario(db, user_id=1)

        # 3. Assert: Verificar que se creó una alerta de ADVERTENCIA
        alertas = db.query(Alert).filter(Alert.user_id == 1).all()
        assert len(alertas) == 1
        assert alertas[0].tipo == TipoAlerta.ADVERTENCIA
        assert "Límite del 80%" in alertas[0].titulo

    def test_regla_critica_gasto_inusual(self, db):
        # 1. Arrange: Historial anterior en COMIDA
        hoy = date.today()
        if hoy.month == 1:
            m_prev1, a_prev1 = 11, hoy.year - 1
            m_prev2, a_prev2 = 12, hoy.year - 1
        elif hoy.month == 2:
            m_prev1, a_prev1 = 12, hoy.year - 1
            m_prev2, a_prev2 = 1, hoy.year
        else:
            m_prev1, a_prev1 = hoy.month - 2, hoy.year
            m_prev2, a_prev2 = hoy.month - 1, hoy.year

        # Historial de meses anteriores en base de datos
        db.add(Expense(user_id=1, categoria=CategoriaGasto.COMIDA, monto=100.0, fecha=date(a_prev1, m_prev1, 5), fuente=FuenteGasto.MANUAL))
        db.add(Expense(user_id=1, categoria=CategoriaGasto.COMIDA, monto=100.0, fecha=date(a_prev2, m_prev2, 5), fuente=FuenteGasto.MANUAL))
        db.commit()

        # Mes actual: creamos presupuesto y registramos gasto
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.COMIDA, monto=200.0, descripcion="Gasto inusual", comercio=None, fecha=date(hoy.year, hoy.month, 15))

        # 2. Act
        with patch("core.smart_alerts.date") as mock_date:
            mock_date.today.return_value = date(hoy.year, hoy.month, 15)
            generar_alertas_usuario(db, user_id=1)

        # 3. Assert: Verificar alerta crítica
        alerta = db.query(Alert).filter(and_(Alert.user_id == 1, Alert.tipo == TipoAlerta.CRITICA)).first()
        assert alerta is not None
        assert "Gasto Inusual: Comida" in alerta.titulo

    def test_regla_informativa_meta_casi_lista(self, db):
        # 1. Arrange
        hoy = date.today()
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        meta = crear_meta(db, user_id=1, nombre="Viaje", monto_obj=1000)
        # Aportar 950 (95%, entre el rango 90% - 99%)
        from core.goals import aportar_a_meta
        aportar_a_meta(db, user_id=1, goal_id=meta.id, monto=950)

        # 2. Act
        with patch("core.smart_alerts.date") as mock_date:
            mock_date.today.return_value = date(hoy.year, hoy.month, 15)
            generar_alertas_usuario(db, user_id=1)

        # 3. Assert
        alerta = db.query(Alert).filter(and_(Alert.user_id == 1, Alert.tipo == TipoAlerta.INFORMATIVA)).first()
        assert alerta is not None
        assert "Meta casi lista: Viaje" in alerta.titulo

    def test_obtener_alertas_priorizadas(self, db):
        # Arrange: Agregar manualmente alertas no leídas de distinta prioridad
        db.add(Alert(user_id=1, titulo="A", mensaje="A", tipo=TipoAlerta.MOTIVACIONAL, leida=False))
        db.add(Alert(user_id=1, titulo="B", mensaje="B", tipo=TipoAlerta.CRITICA, leida=False))
        db.add(Alert(user_id=1, titulo="C", mensaje="C", tipo=TipoAlerta.ADVERTENCIA, leida=False))
        db.commit()

        # Act
        with patch("core.smart_alerts.generar_alertas_usuario") as mock_gen:
            alertas = obtener_alertas_priorizadas(db, user_id=1)

        # Assert: Orden esperado: CRITICA -> ADVERTENCIA -> MOTIVACIONAL
        assert len(alertas) == 3
        assert alertas[0].tipo == TipoAlerta.CRITICA
        assert alertas[1].tipo == TipoAlerta.ADVERTENCIA
        assert alertas[2].tipo == TipoAlerta.MOTIVACIONAL


# ════════════════════════════════════════════════════════════════════════════
# SECCIÓN 4: Tests de core/smartscore.py
# ════════════════════════════════════════════════════════════════════════════

class TestSmartScore:
    """Pruebas para el cálculo del score de salud financiera."""

    def test_calcular_score_perfecto(self, db):
        # Arrange:
        hoy = date.today()
        # 1. 0% de presupuesto usado -> 40 pts
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        # 2. Meta en progreso -> 30 pts
        meta = crear_meta(db, user_id=1, nombre="Ahorro", monto_obj=1000)
        from core.goals import aportar_a_meta
        aportar_a_meta(db, user_id=1, goal_id=meta.id, monto=100)
        # 3. Cero alertas críticas -> 20 pts
        # 4. Ahorro mayor al mes anterior (mes anterior disponible: 200, mes actual disponible: 900) -> 10 pts
        if hoy.month == 1:
            m_prev, a_prev = 12, hoy.year - 1
        else:
            m_prev, a_prev = hoy.month - 1, hoy.year
        crear_presupuesto_mes(db, user_id=1, monto_base=200, mes=m_prev, anio=a_prev)

        # Act
        with patch("core.smartscore.date") as mock_date:
            mock_date.today.return_value = date(hoy.year, hoy.month, 20)
            score = calcular_score(db, user_id=1)

        # Assert: 40 + 30 + 20 + 10 = 100
        assert score == 100

    def test_calcular_score_criterios_bajos(self, db):
        # Arrange:
        hoy = date.today()
        # 1. 100% de presupuesto usado -> 0 pts
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)
        registrar_gasto(db, user_id=1, categoria=CategoriaGasto.OTROS, monto=1000.0, descripcion="Gasto total", comercio=None, fecha=date(hoy.year, hoy.month, 10))
        # 2. Sin metas -> 0 pts
        # 3. Dos alertas críticas este mes -> -20 pts del criterio de alertas (da 0 pts)
        db.add(Alert(user_id=1, titulo="Critica 1", mensaje="1", tipo=TipoAlerta.CRITICA, created_at=datetime(hoy.year, hoy.month, 12)))
        db.add(Alert(user_id=1, titulo="Critica 2", mensaje="2", tipo=TipoAlerta.CRITICA, created_at=datetime(hoy.year, hoy.month, 14)))
        db.commit()
        # 4. No supera al mes anterior (anterior: 500, actual disponible: 0) -> 0 pts
        if hoy.month == 1:
            m_prev, a_prev = 12, hoy.year - 1
        else:
            m_prev, a_prev = hoy.month - 1, hoy.year
        crear_presupuesto_mes(db, user_id=1, monto_base=500, mes=m_prev, anio=a_prev)

        # Act
        with patch("core.smartscore.date") as mock_date:
            mock_date.today.return_value = date(hoy.year, hoy.month, 20)
            score = calcular_score(db, user_id=1)

        # Assert: 0 + 0 + 0 + 0 = 0
        assert score == 0

    def test_guardar_snapshot_crea_y_actualiza(self, db):
        # Arrange
        hoy = date.today()
        crear_presupuesto_mes(db, user_id=1, monto_base=1000, mes=hoy.month, anio=hoy.year)

        with patch("core.smartscore.date") as mock_date:
            mock_date.today.return_value = date(hoy.year, hoy.month, 20)
            # Act 1: Guardar primer snapshot
            snap1 = guardar_snapshot(db, user_id=1)
            score_anterior = snap1.score
            
            # Assert 1
            assert snap1.id is not None
            assert score_anterior > 0
            assert snap1.mes == hoy.month
            assert snap1.anio == hoy.year

            # Modificar presupuesto para alterar el score
            registrar_gasto(db, user_id=1, categoria=CategoriaGasto.OTROS, monto=500.0, descripcion="Gasto", comercio=None, fecha=date(hoy.year, hoy.month, 10))
            
            # Act 2: Guardar segundo snapshot (debería actualizar el existente)
            snap2 = guardar_snapshot(db, user_id=1)

            # Assert 2: mismo ID pero diferente score
            assert snap1.id == snap2.id
            assert snap2.score < score_anterior

    def test_obtener_historial_score(self, db):
        # Arrange: Añadir snapshots de distintos meses
        hoy = date.today()
        if hoy.month >= 3:
            m1, m2, m3 = hoy.month - 2, hoy.month - 1, hoy.month
            y1, y2, y3 = hoy.year, hoy.year, hoy.year
        elif hoy.month == 2:
            m1, m2, m3 = 12, 1, 2
            y1, y2, y3 = hoy.year - 1, hoy.year, hoy.year
        else:
            m1, m2, m3 = 11, 12, 1
            y1, y2, y3 = hoy.year - 1, hoy.year - 1, hoy.year

        db.add(SmartScoreSnapshot(user_id=1, score=85, mes=m1, anio=y1, fecha_calculo=datetime(y1, m1, 28)))
        db.add(SmartScoreSnapshot(user_id=1, score=90, mes=m2, anio=y2, fecha_calculo=datetime(y2, m2, 28)))
        db.add(SmartScoreSnapshot(user_id=1, score=95, mes=m3, anio=y3, fecha_calculo=datetime(y3, m3, 28)))
        db.commit()

        # Act
        historial = obtener_historial_score(db, user_id=1, meses=3)

        # Assert: Orden cronológico ascendente (antiguo a reciente)
        assert len(historial) == 3
        assert historial[0]["score"] == 85
        assert historial[0]["mes"] == m1
        assert historial[1]["score"] == 90
        assert historial[1]["mes"] == m2
        assert historial[2]["score"] == 95
        assert historial[2]["mes"] == m3
