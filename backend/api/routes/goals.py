from fastapi import APIRouter, Depends, HTTPException
from api.schemas.goals import GoalCreate, GoalContribute
from api.dependencies import get_db, get_current_user
from core.goals import listar_metas_con_progreso, crear_meta, aportar_a_meta
from core.exceptions import SaldoInsuficienteError
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
        return crear_meta(db, user.id, req.nombre, req.monto_objetivo)
    except MetaLimiteError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/{goal_id}/contribute")
def contribute_to_goal(goal_id: int, req: GoalContribute, db=Depends(get_db), user=Depends(get_current_user)):
    try:
        return aportar_a_meta(db, user.id, goal_id, req.monto)
    except SaldoInsuficienteError as e:
        raise HTTPException(status_code=422, detail=str(e))
