from fastapi import APIRouter, Depends, HTTPException
from api.schemas.budgets import BudgetCreate, BudgetIncome
from api.dependencies import get_db, get_current_user
from core.budgets import crear_presupuesto_mes, calcular_resumen_mensual, agregar_ingreso_adicional
from core.exceptions import PresupuestoNoEncontradoError

router = APIRouter()

@router.post("/")
def create_budget(req: BudgetCreate, db=Depends(get_db), user=Depends(get_current_user)):
    return crear_presupuesto_mes(db, user.id, req.monto_base, req.mes, req.año)

@router.get("/current")
def get_current_budget(db=Depends(get_db), user=Depends(get_current_user)):
    try:
        return calcular_resumen_mensual(db, user.id)
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/income")
def add_income(req: BudgetIncome, db=Depends(get_db), user=Depends(get_current_user)):
    try:
        return agregar_ingreso_adicional(db, user.id, req.monto, req.descripcion)
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(status_code=404, detail=str(e))
