from fastapi import APIRouter, Depends, HTTPException
from api.schemas.simulator import SimulationRequest, SimulationResponse
from api.dependencies import get_db, get_current_user
from core import simulator as simulator_core
from core import budgets as budgets_core
from core import goals as goals_core
from core.exceptions import PresupuestoNoEncontradoError

router = APIRouter()

@router.post("/", response_model=SimulationResponse)
def simular_compra(
    req: SimulationRequest,
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    from db.models import Goal
    from core.enums import EstadoMeta

    try:
        # Obtener presupuesto activo para el saldo_disponible (Lanza HTTP 404 si no existe)
        budget = budgets_core.obtener_presupuesto_activo(db, user.id)
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(404, str(e))

    # Obtener metas activas en progreso
    metas = db.query(Goal).filter(
        Goal.user_id == user.id, 
        Goal.estado == EstadoMeta.EN_PROGRESO
    ).all()
    
    metas_dict = [
        {
            "nombre": g.nombre, 
            "monto_objetivo": g.monto_objetivo,
            "saldo_acumulado": g.saldo_acumulado,
            "faltante": g.monto_objetivo - g.saldo_acumulado
        } 
        for g in metas
    ]

    # Llamar al simulador (stateless)
    resultado = simulator_core.simular_compra(budget.saldo_disponible, req.monto_compra, metas_dict)
    
    return resultado
