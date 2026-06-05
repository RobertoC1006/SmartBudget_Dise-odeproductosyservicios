"""
core/goals.py — Sistema de gestión de metas de ahorro (Trasvase Atómico)

Lógica de Negocio:
El ahorro se considera un "gasto virtual" que reserva dinero del presupuesto.
Esto evita que el usuario vea saldo disponible que ya está comprometido para una meta.
"""

from datetime import date
from sqlalchemy.orm import Session
from sqlalchemy import and_

from db.models import Goal, Budget
from core.enums import EstadoMeta
from core.exceptions import (
    SaldoInsuficienteError, 
    MetaCompletadaError, 
    MetaLimiteError,
    MetaNoEncontradaError
)
from core.budgets import obtener_presupuesto_activo
from core.config import settings

def crear_meta(db: Session, user_id: int, nombre: str, monto_obj: float, fecha_lim: date = None) -> Goal:
    """
    Crea una nueva meta. Valida que el usuario no exceda el límite definido en config.py.
    """
    # Validar límite de metas activas
    metas_activas = db.query(Goal).filter(
        and_(
            Goal.user_id == user_id,
            Goal.estado != EstadoMeta.COMPLETADA,
            Goal.estado != EstadoMeta.CANCELADA
        )
    ).count()

    if metas_activas >= settings.MAX_METAS_ACTIVAS:
        raise MetaLimiteError(f"Solo puedes tener hasta {settings.MAX_METAS_ACTIVAS} metas activas.")

    nueva_meta = Goal(
        user_id=user_id,
        nombre=nombre,
        monto_objetivo=monto_obj,
        fecha_limite=fecha_lim,
        estado=EstadoMeta.PENDIENTE
    )
    db.add(nueva_meta)
    db.commit()
    db.refresh(nueva_meta)
    return nueva_meta

def aportar_a_meta(db: Session, user_id: int, goal_id: int, monto: float) -> Goal:
    """
    Traslada dinero del Presupuesto Activo hacia la Meta.
    
    Validaciones:
    1. Que exista presupuesto para este mes.
    2. Que el presupuesto tenga saldo suficiente.
    3. Que la meta no esté ya completada.
    """
    # 1. Obtener recursos
    budget = obtener_presupuesto_activo(db, user_id)
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == user_id).first()
    
    if not goal:
        raise MetaNoEncontradaError("La meta no existe o no te pertenece.")
    
    if goal.estado == EstadoMeta.COMPLETADA:
        raise MetaCompletadaError("Esta meta ya ha sido alcanzada.")

    # 2. Validar saldo disponible en el presupuesto
    if budget.saldo_disponible < monto:
        raise SaldoInsuficienteError(
            f"No tienes saldo suficiente en tu presupuesto mensual. Disponible: S/. {budget.saldo_disponible}"
        )

    # 3. Trasvase de fondos
    budget.saldo_disponible -= monto
    goal.saldo_acumulado += monto

    # 4. Actualizar estado de la meta
    if goal.saldo_acumulado >= goal.monto_objetivo:
        goal.estado = EstadoMeta.COMPLETADA
    else:
        goal.estado = EstadoMeta.EN_PROGRESO

    db.commit()
    db.refresh(goal)
    return goal

def retirar_de_meta(db: Session, user_id: int, goal_id: int, monto: float) -> Goal:
    """
    Devuelve dinero de una meta hacia el Presupuesto Activo.
    Se usa en "emergencias" o cuando el usuario decide ahorrar menos.
    """
    budget = obtener_presupuesto_activo(db, user_id)
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == user_id).first()

    if not goal or goal.saldo_acumulado < monto:
        raise SaldoInsuficienteError("No tienes esa cantidad ahorrada en esta meta.")

    # Trasvase inverso
    goal.saldo_acumulado -= monto
    budget.saldo_disponible += monto

    # Ajustar estado
    if goal.saldo_acumulado < goal.monto_objetivo:
        goal.estado = EstadoMeta.EN_PROGRESO if goal.saldo_acumulado > 0 else EstadoMeta.PENDIENTE

    db.commit()
    db.refresh(goal)
    return goal

def listar_metas_con_progreso(db: Session, user_id: int) -> list:
    """
    Calcula el porcentaje de progreso para cada meta en tiempo real.
    """
    metas = db.query(Goal).filter(Goal.user_id == user_id).all()
    resultado = []
    
    for m in metas:
        porcentaje = (m.saldo_acumulado / m.monto_objetivo * 100) if m.monto_objetivo > 0 else 0
        resultado.append({
            "id": m.id,
            "nombre": m.nombre,
            "monto_objetivo": m.monto_objetivo,
            "saldo_acumulado": m.saldo_acumulado,
            "estado": m.estado,
            "porcentaje": round(porcentaje, 2),
            "faltante": round(max(0, m.monto_objetivo - m.saldo_acumulado), 2)
        })
    
    return resultado
