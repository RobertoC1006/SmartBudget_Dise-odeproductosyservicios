"""
core/goals.py — Sistema de gestión de metas de ahorro (Trasvase Atómico)

Lógica de Negocio:
El ahorro se considera un "gasto virtual" que reserva dinero del presupuesto.
Esto evita que el usuario vea saldo disponible que ya está comprometido para una meta.
"""

from datetime import date
from sqlalchemy.orm import Session
from sqlalchemy import and_

from db.models import Goal, Budget, GoalContribution
from core.enums import EstadoMeta, CategoriaMeta
from core.exceptions import (
    SaldoInsuficienteError,
    MetaCompletadaError,
    MetaLimiteError,
    MetaNoEncontradaError
)
from core.budgets import obtener_presupuesto_activo
from core.config import settings

def crear_meta(
    db: Session,
    user_id: int,
    nombre: str,
    monto_obj: float,
    fecha_lim: date = None,
    categoria: CategoriaMeta = None,
    recordatorio: bool = False,
) -> Goal:
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
        categoria=(categoria.value if categoria else CategoriaMeta.OTROS.value),
        recordatorio=recordatorio,
        estado=EstadoMeta.PENDIENTE
    )
    db.add(nueva_meta)
    db.commit()
    db.refresh(nueva_meta)
    return nueva_meta

def editar_meta(
    db: Session,
    user_id: int,
    goal_id: int,
    nombre: str = None,
    monto_obj: float = None,
    fecha_lim: date = None,
    categoria: CategoriaMeta = None,
    recordatorio: bool = None,
) -> Goal:
    """
    Edita los campos de una meta. Solo se actualizan los parámetros que se envían
    (los que quedan en None se dejan intactos), salvo `fecha_lim`, que se aplica
    siempre para permitir limpiar la fecha objetivo desde el detalle.

    Si el nuevo monto objetivo queda por debajo del saldo acumulado, la meta
    pasa a COMPLETADA; si se sube por encima, vuelve a EN_PROGRESO/PENDIENTE.
    """
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == user_id).first()

    if not goal:
        raise MetaNoEncontradaError("La meta no existe o no te pertenece.")

    if nombre is not None:
        goal.nombre = nombre
    if monto_obj is not None:
        goal.monto_objetivo = monto_obj
    if categoria is not None:
        goal.categoria = categoria.value
    if recordatorio is not None:
        goal.recordatorio = recordatorio
    goal.fecha_limite = fecha_lim

    # Recalcular el estado tras un posible cambio de monto objetivo.
    if goal.saldo_acumulado >= goal.monto_objetivo:
        goal.estado = EstadoMeta.COMPLETADA
    elif goal.saldo_acumulado > 0:
        goal.estado = EstadoMeta.EN_PROGRESO
    else:
        goal.estado = EstadoMeta.PENDIENTE

    db.commit()
    db.refresh(goal)
    return goal

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

    # 4. Registrar el aporte en el historial (misma transacción que el trasvase)
    db.add(GoalContribution(goal_id=goal.id, user_id=user_id, monto=monto))

    # 5. Actualizar estado de la meta
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

def eliminar_meta(db: Session, user_id: int, goal_id: int) -> None:
    """
    Elimina una meta. Si tiene saldo acumulado, lo devuelve al presupuesto
    activo para que el dinero reservado no se pierda.
    """
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == user_id).first()

    if not goal:
        raise MetaNoEncontradaError("La meta no existe o no te pertenece.")

    if goal.saldo_acumulado > 0:
        budget = obtener_presupuesto_activo(db, user_id)
        budget.saldo_disponible += goal.saldo_acumulado

    db.delete(goal)
    db.commit()

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
            "user_id": m.user_id,
            "nombre": m.nombre,
            "descripcion": m.descripcion,
            "monto_objetivo": m.monto_objetivo,
            "saldo_acumulado": m.saldo_acumulado,
            "fecha_limite": m.fecha_limite.isoformat() if m.fecha_limite else None,
            "estado": m.estado,
            "categoria": m.categoria,
            "recordatorio": m.recordatorio,
            "created_at": m.created_at.isoformat() if m.created_at else None,
            "porcentaje": round(porcentaje, 2),
            "faltante": round(max(0, m.monto_objetivo - m.saldo_acumulado), 2)
        })

    return resultado

def listar_aportes(db: Session, user_id: int, goal_id: int) -> list:
    """
    Devuelve el historial de aportes de una meta, del más antiguo al más reciente,
    para construir el gráfico de progreso real en el detalle de meta.
    """
    goal = db.query(Goal).filter(Goal.id == goal_id, Goal.user_id == user_id).first()
    if not goal:
        raise MetaNoEncontradaError("La meta no existe o no te pertenece.")

    aportes = db.query(GoalContribution).filter(
        GoalContribution.goal_id == goal_id
    ).order_by(GoalContribution.created_at.asc()).all()

    return [
        {
            "id": a.id,
            "monto": a.monto,
            "created_at": a.created_at.isoformat() if a.created_at else None,
        }
        for a in aportes
    ]
