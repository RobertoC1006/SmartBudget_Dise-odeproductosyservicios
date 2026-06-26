"""
core/profile.py — Métricas reales del perfil del usuario

Alimenta el "Resumen personal" de la pantalla de Perfil (1A) en una sola
llamada, reutilizando datos que ya viven en el dominio (metas, gastos y
SmartScore). No introduce tablas ni columnas nuevas.

Nota: "Días racha" del mockup NO se calcula aquí — no hay tracking de actividad
diaria, así que en Flutter es un placeholder visual marcado para el futuro.
"""

from sqlalchemy.orm import Session
from sqlalchemy import and_, func

from db.models import Goal, Expense
from core.enums import EstadoMeta
from core.exceptions import PresupuestoNoEncontradoError
from core import smartscore as smartscore_core


def obtener_resumen_perfil(db: Session, user_id: int) -> dict:
    """
    Devuelve las métricas reales del Resumen personal (1A):

    - metas_activas:      nº de metas no completadas ni canceladas.
    - gastos_registrados: nº total de gastos del usuario (histórico).
    - dinero_ahorrado:    suma del saldo acumulado en todas las metas.
    - smartscore:         SmartScore actual; None si no hay presupuesto activo.
    - smartscore_delta:   variación vs. el snapshot del mes anterior
                          (0 si no hay al menos dos snapshots).

    El cálculo es defensivo: la ausencia de presupuesto no rompe la respuesta.
    """
    metas_activas = db.query(Goal).filter(
        and_(
            Goal.user_id == user_id,
            Goal.estado != EstadoMeta.COMPLETADA,
            Goal.estado != EstadoMeta.CANCELADA,
        )
    ).count()

    gastos_registrados = db.query(Expense).filter(
        Expense.user_id == user_id
    ).count()

    dinero_ahorrado = db.query(
        func.coalesce(func.sum(Goal.saldo_acumulado), 0.0)
    ).filter(Goal.user_id == user_id).scalar()

    # SmartScore actual (defensivo: sin presupuesto activo queda en None).
    try:
        smartscore = smartscore_core.calcular_score(db, user_id)
    except PresupuestoNoEncontradoError:
        smartscore = None

    # Variación vs. mes anterior a partir de los snapshots guardados,
    # con la misma lógica que el Dashboard (último - penúltimo).
    historial = smartscore_core.obtener_historial_score(db, user_id, meses=6)
    if len(historial) >= 2:
        smartscore_delta = historial[-1]["score"] - historial[-2]["score"]
    else:
        smartscore_delta = 0

    return {
        "metas_activas": metas_activas,
        "gastos_registrados": gastos_registrados,
        "dinero_ahorrado": float(dinero_ahorrado),
        "smartscore": smartscore,
        "smartscore_delta": smartscore_delta,
    }
