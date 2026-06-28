from typing import List
from fastapi import APIRouter, Depends, HTTPException
from api.schemas.goals import (
    GoalCreate,
    GoalUpdate,
    GoalContribute,
    ContributionResponse,
    ContributeResult,
    ContributePreviewResponse,
)
from api.dependencies import get_db, get_current_user
from core.goals import (
    listar_metas_con_progreso,
    crear_meta,
    aportar_a_meta,
    eliminar_meta,
    editar_meta,
    listar_aportes,
    previsualizar_impacto_aporte,
)
from core import smartscore as smartscore_core
from core.exceptions import (
    SaldoInsuficienteError,
    MetaCompletadaError,
    MetaNoEncontradaError,
    PresupuestoNoEncontradoError,
)
# Intentar importar MetaLimiteError, pero si Roberto no lo puso, capturamos Exception genérico o creamos un workaround
try:
    from core.exceptions import MetaLimiteError
except ImportError:
    class MetaLimiteError(Exception): pass

router = APIRouter()

@router.get("/")
def get_goals(db=Depends(get_db), user=Depends(get_current_user)):
    return listar_metas_con_progreso(db, user.id)

@router.post("/")
def create_new_goal(req: GoalCreate, db=Depends(get_db), user=Depends(get_current_user)):
    try:
        return crear_meta(
            db,
            user.id,
            req.nombre,
            req.monto_objetivo,
            fecha_lim=req.fecha_limite,
            categoria=req.categoria,
            recordatorio=req.recordatorio,
        )
    except MetaLimiteError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/{goal_id}")
def update_goal(goal_id: int, req: GoalUpdate, db=Depends(get_db), user=Depends(get_current_user)):
    try:
        return editar_meta(
            db,
            user.id,
            goal_id,
            nombre=req.nombre,
            monto_obj=req.monto_objetivo,
            fecha_lim=req.fecha_limite,
            categoria=req.categoria,
            recordatorio=req.recordatorio,
        )
    except MetaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/{goal_id}/contributions", response_model=List[ContributionResponse])
def get_goal_contributions(goal_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    try:
        return listar_aportes(db, user.id, goal_id)
    except MetaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/{goal_id}/contribute", response_model=ContributeResult)
def contribute_to_goal(goal_id: int, req: GoalContribute, db=Depends(get_db), user=Depends(get_current_user)):
    try:
        # SmartScore antes del aporte (para medir el impacto real en finanzas)
        score_anterior = _safe_score(db, user.id)

        goal = aportar_a_meta(
            db, user.id, goal_id, req.monto,
            fecha=req.fecha, descripcion=req.descripcion,
        )

        # Recalcular y persistir el snapshot del mes tras el aporte
        score_nuevo = _safe_score(db, user.id, persistir=True)

        return ContributeResult(
            id=goal.id,
            user_id=goal.user_id,
            nombre=goal.nombre,
            monto_objetivo=goal.monto_objetivo,
            saldo_acumulado=goal.saldo_acumulado,
            fecha_limite=goal.fecha_limite,
            estado=goal.estado.value,
            recordatorio=goal.recordatorio,
            score_anterior=score_anterior,
            score_nuevo=score_nuevo,
            score_delta=score_nuevo - score_anterior,
        )
    except SaldoInsuficienteError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except MetaCompletadaError as e:
        raise HTTPException(status_code=409, detail=str(e))
    except MetaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/{goal_id}/contribute/preview", response_model=ContributePreviewResponse)
def preview_contribution(goal_id: int, req: GoalContribute, db=Depends(get_db), user=Depends(get_current_user)):
    """
    Simula un aporte SIN guardarlo y devuelve el impacto real en el SmartScore
    (para el "+N pts" de la pantalla de Confirmar aporte).
    """
    try:
        return previsualizar_impacto_aporte(db, user.id, goal_id, req.monto)
    except SaldoInsuficienteError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except MetaCompletadaError as e:
        raise HTTPException(status_code=409, detail=str(e))
    except MetaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/{goal_id}", status_code=204)
def delete_goal(goal_id: int, db=Depends(get_db), user=Depends(get_current_user)):
    try:
        eliminar_meta(db, user.id, goal_id)
    except MetaNoEncontradaError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except PresupuestoNoEncontradoError:
        raise HTTPException(
            status_code=422,
            detail="La meta tiene ahorro acumulado pero no hay un presupuesto activo donde devolverlo."
        )


def _safe_score(db, user_id: int, persistir: bool = False) -> int:
    """
    Calcula el SmartScore tolerando la ausencia de presupuesto (devuelve 0),
    para que el cálculo del delta nunca rompa el flujo de aporte.
    """
    try:
        if persistir:
            return smartscore_core.guardar_snapshot(db, user_id).score
        return smartscore_core.calcular_score(db, user_id)
    except PresupuestoNoEncontradoError:
        return 0
