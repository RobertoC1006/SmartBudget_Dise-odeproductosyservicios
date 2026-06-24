from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from api.schemas.expense import ExpenseCreate, ExpenseResponse, ScanResponse
from api.dependencies import get_db, get_current_user
from core.enums import CategoriaGasto
from core import expenses as expenses_core
from core import ai as ai_core
from core.exceptions import (
    SaldoInsuficienteError,
    PresupuestoNoEncontradoError,
    GastoNoEncontradoError,
    OCRFallidoError
)

router = APIRouter()


@router.get("/", response_model=list[ExpenseResponse])
def listar_gastos(
    mes: int = None,
    año: int = None,
    categoria: CategoriaGasto = None,
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    from datetime import date
    mes = mes or date.today().month
    año = año or date.today().year
    return expenses_core.listar_gastos_mes(db, user.id, mes, año, categoria)


@router.get("/recent", response_model=list[ExpenseResponse])
def listar_gastos_recientes(
    limite: int = 5,
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    """Últimos gastos registrados (por created_at), sin filtrar por mes.

    Alimenta "Actividad reciente" del Dashboard.
    """
    return expenses_core.listar_gastos_recientes(db, user.id, limite)


@router.post("/", response_model=ExpenseResponse, status_code=201)
def crear_gasto(
    req: ExpenseCreate,
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    try:
        return expenses_core.registrar_gasto(
            db, user.id, req.categoria, req.monto,
            req.descripcion, req.comercio, req.fecha, req.fuente
        )
    except SaldoInsuficienteError as e:
        raise HTTPException(422, str(e))
    except PresupuestoNoEncontradoError as e:
        raise HTTPException(404, str(e))


@router.post("/scan", response_model=ScanResponse)
async def escanear_ticket(
    file: UploadFile = File(...),
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    if file.content_type == "application/pdf":
        raise HTTPException(501, "La extracción de datos desde archivos PDF aún no está soportada en esta versión.")
    
    content = await file.read()
    try:
        resultado = await ai_core.extraer_gasto_desde_imagen(content, file.content_type)
        return resultado
    except OCRFallidoError as e:
        raise HTTPException(422, str(e))


@router.delete("/{expense_id}", status_code=204)
def eliminar(
    expense_id: int,
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    try:
        expenses_core.eliminar_gasto(db, user.id, expense_id)
    except GastoNoEncontradoError as e:
        raise HTTPException(404, str(e))


@router.get("/summary")
def resumen_categorias(
    mes: int = None,
    año: int = None,
    db=Depends(get_db),
    user=Depends(get_current_user)
):
    from datetime import date
    return expenses_core.calcular_gastos_por_categoria(
        db, user.id, mes or date.today().month, año or date.today().year
    )
