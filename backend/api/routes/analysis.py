from datetime import date

from fastapi import APIRouter, Depends

from api.dependencies import get_db, get_current_user
from api.schemas.analysis import OverviewResponse, CategoryDetailResponse
from core import analysis as analysis_core
from core.enums import CategoriaGasto

router = APIRouter()


@router.get("/overview", response_model=OverviewResponse)
def overview(
    mes: int = None,
    año: int = None,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    """Métricas de la pantalla 1A (gasto/ingresos/ahorro) + valores del mes anterior."""
    hoy = date.today()
    return analysis_core.resumen_overview(db, user.id, mes or hoy.month, año or hoy.year)


@router.get("/category-detail", response_model=CategoryDetailResponse)
def category_detail(
    categoria: CategoriaGasto,
    mes: int = None,
    año: int = None,
    db=Depends(get_db),
    user=Depends(get_current_user),
):
    """Detalle de una categoría (pantalla 1D): total, comparativa, % y desglose por comercio."""
    hoy = date.today()
    return analysis_core.detalle_categoria(db, user.id, categoria, mes or hoy.month, año or hoy.year)
