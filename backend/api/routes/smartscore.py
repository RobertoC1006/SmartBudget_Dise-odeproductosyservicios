from fastapi import APIRouter, Depends, HTTPException
from typing import List
from api.dependencies import get_db, get_current_user
from api.schemas.smartscore import ScoreResponse, SnapshotResponse, SnapshotHistoryResponse
from core import smartscore as smartscore_core
from core.exceptions import PresupuestoNoEncontradoError

router = APIRouter()

@router.get("/", response_model=ScoreResponse)
def obtener_score(
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Calcula el SmartScore actual del usuario basándose en su comportamiento mensual.
    Lanza HTTP 404 si el usuario no tiene un presupuesto activo.
    """
    try:
        resultado = smartscore_core.calcular_score_con_desglose(db, user.id)
        return ScoreResponse(score=resultado["score"], desglose=resultado["desglose"])
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/snapshot", response_model=SnapshotResponse, status_code=201)
def crear_snapshot(
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Calcula el SmartScore actual y guarda o actualiza un snapshot para el mes actual.
    Lanza HTTP 404 si el usuario no tiene un presupuesto activo.
    """
    try:
        snapshot = smartscore_core.guardar_snapshot(db, user.id)
        return snapshot
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/history", response_model=List[SnapshotHistoryResponse])
def listar_historial(
    meses: int = 6,
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    """
    Retorna el historial de puntuaciones del usuario de los últimos N meses,
    ordenados cronológicamente (del más antiguo al más reciente).
    """
    return smartscore_core.obtener_historial_score(db, user.id, meses=meses)
