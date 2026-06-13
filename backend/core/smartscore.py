"""
core/smartscore.py — Motor de Salud Financiera (SmartScore)
Calificación del comportamiento financiero del usuario de 0 a 100 puntos.

Reglas del Score:
1. % Presupuesto Usado (40 pts max):
   - Escala lineal de 40 a 0 puntos.
   - 0% usado = 40 pts.
   - 100% o más usado = 0 pts.
2. Metas de ahorro activas con progreso (30 pts max) — criterio GRADUADO:
   - 10 pts base por tener al menos una meta activa con saldo_acumulado > 0.
   - + hasta 20 pts proporcionales al progreso promedio de las metas activas
     (EN_PROGRESO y COMPLETADA; las completadas cuentan como 100%).
   - Así cada aporte sube el promedio y mueve el score de forma real.
3. Ausencia de gastos inusuales (20 pts max):
   - Se restan 10 puntos por cada alerta CRÍTICA generada en el mes actual.
   - Mínimo 0 pts.
4. Incremento de ahorro vs mes anterior (10 pts max):
   - Si el saldo disponible del mes actual es mayor que el saldo disponible del mes anterior = 10 pts.
   - De lo contrario (o si es el primer mes) = 0 pts.
"""

from datetime import date, datetime
from sqlalchemy.orm import Session
from sqlalchemy import and_, extract, desc

from db.models import SmartScoreSnapshot, Budget, Alert, Goal
from core.enums import TipoAlerta, EstadoMeta
from core.budgets import obtener_presupuesto_activo
from core.exceptions import PresupuestoNoEncontradoError


def calcular_score_con_desglose(db: Session, user_id: int) -> dict:
    """
    Calcula el SmartScore y devuelve el detalle por criterio.

    Retorna: {"score": int, "desglose": {presupuesto, metas, alertas, ahorro}}
    donde cada valor del desglose son los puntos enteros que aporta ese criterio.
    Lanza PresupuestoNoEncontradoError si el usuario no tiene un presupuesto activo.
    """
    hoy = date.today()
    mes_actual = hoy.month
    anio_actual = hoy.year

    # 1. Obtener presupuesto activo (Lanza PresupuestoNoEncontradoError si no existe)
    budget = obtener_presupuesto_activo(db, user_id)

    # --- CRITERIO 1: % Presupuesto Usado (40 pts) ---
    total_ingresos = budget.monto_base + budget.ingresos_adicionales
    if total_ingresos > 0:
        porcentaje_gastado = (budget.total_gastado / total_ingresos) * 100
        puntos_presupuesto = max(0.0, min(40.0, 40.0 * (1.0 - porcentaje_gastado / 100.0)))
    else:
        puntos_presupuesto = 0.0

    # --- CRITERIO 2: Metas activas con progreso (30 pts, GRADUADO) ---
    # 10 pts base por tener una meta con ahorro + hasta 20 pts según el progreso
    # promedio de las metas activas (las completadas cuentan como 100%).
    metas_activas = db.query(Goal).filter(
        and_(
            Goal.user_id == user_id,
            Goal.estado.in_([EstadoMeta.EN_PROGRESO, EstadoMeta.COMPLETADA]),
            Goal.saldo_acumulado > 0
        )
    ).all()

    if metas_activas:
        suma_progreso = 0.0
        for m in metas_activas:
            if m.monto_objetivo > 0:
                suma_progreso += min(1.0, m.saldo_acumulado / m.monto_objetivo)
            else:
                suma_progreso += 1.0
        progreso_promedio = suma_progreso / len(metas_activas)
        puntos_metas = 10.0 + (20.0 * progreso_promedio)
    else:
        puntos_metas = 0.0

    # --- CRITERIO 3: Sin gastos inusuales (20 pts) ---
    # Contamos las alertas críticas del mes actual
    alertas_criticas = db.query(Alert).filter(
        and_(
            Alert.user_id == user_id,
            Alert.tipo == TipoAlerta.CRITICA,
            extract('month', Alert.created_at) == mes_actual,
            extract('year', Alert.created_at) == anio_actual
        )
    ).count()
    puntos_alertas = max(0.0, 20.0 - (alertas_criticas * 10.0))

    # --- CRITERIO 4: Ahorro vs mes anterior (10 pts) ---
    # Calcular mes anterior
    if mes_actual == 1:
        mes_prev = 12
        anio_prev = anio_actual - 1
    else:
        mes_prev = mes_actual - 1
        anio_prev = anio_actual

    budget_previo = db.query(Budget).filter(
        and_(
            Budget.user_id == user_id,
            Budget.mes == mes_prev,
            Budget.anio == anio_prev
        )
    ).first()

    if budget_previo and budget.saldo_disponible > budget_previo.saldo_disponible:
        puntos_ahorro = 10.0
    else:
        puntos_ahorro = 0.0

    score_final = int(round(puntos_presupuesto + puntos_metas + puntos_alertas + puntos_ahorro))
    return {
        "score": max(0, min(100, score_final)),
        "desglose": {
            "presupuesto": int(round(puntos_presupuesto)),
            "metas": int(round(puntos_metas)),
            "alertas": int(round(puntos_alertas)),
            "ahorro": int(round(puntos_ahorro)),
        },
    }


def calcular_score(db: Session, user_id: int) -> int:
    """
    Calcula el SmartScore actual del usuario basándose en su comportamiento mensual.
    Lanza PresupuestoNoEncontradoError si el usuario no tiene un presupuesto activo.
    """
    return calcular_score_con_desglose(db, user_id)["score"]


def guardar_snapshot(db: Session, user_id: int) -> SmartScoreSnapshot:
    """
    Calcula el SmartScore actual y guarda o actualiza un snapshot para el mes actual.
    """
    hoy = date.today()
    mes_actual = hoy.month
    anio_actual = hoy.year

    score = calcular_score(db, user_id)

    # Verificar si ya existe un snapshot para este mes
    snapshot = db.query(SmartScoreSnapshot).filter(
        and_(
            SmartScoreSnapshot.user_id == user_id,
            SmartScoreSnapshot.mes == mes_actual,
            SmartScoreSnapshot.anio == anio_actual
        )
    ).first()

    if snapshot:
        snapshot.score = score
        snapshot.fecha_calculo = datetime.now()
    else:
        snapshot = SmartScoreSnapshot(
            user_id=user_id,
            score=score,
            mes=mes_actual,
            anio=anio_actual
        )
        db.add(snapshot)

    db.commit()
    db.refresh(snapshot)
    return snapshot


def obtener_historial_score(db: Session, user_id: int, meses: int = 6) -> list[dict]:
    """
    Retorna el historial de puntuaciones del usuario de los últimos N meses,
    ordenados cronológicamente (del más antiguo al más reciente).
    """
    snapshots = db.query(SmartScoreSnapshot).filter(
        SmartScoreSnapshot.user_id == user_id
    ).order_by(
        desc(SmartScoreSnapshot.anio),
        desc(SmartScoreSnapshot.mes)
    ).limit(meses).all()

    # Revertimos la lista para presentarla de manera cronológica (antiguo -> nuevo)
    snapshots.reverse()

    return [
        {
            "id": s.id,
            "score": s.score,
            "mes": s.mes,
            "anio": s.anio,
            "fecha_calculo": s.fecha_calculo.isoformat() if s.fecha_calculo else None
        }
        for s in snapshots
    ]
