from pydantic import BaseModel


class OverviewResponse(BaseModel):
    """Resumen general del mes (pantalla 1A) con comparativa al mes anterior."""
    mes: int
    anio: int
    gasto_total: float
    ingresos: float
    ahorro: float
    gasto_total_prev: float
    ingresos_prev: float
    ahorro_prev: float


class MerchantBreakdown(BaseModel):
    """Una fila del desglose por comercio (pantalla 1D)."""
    comercio: str
    total: float
    n_transacciones: int


class CategoryDetailResponse(BaseModel):
    """Detalle de una categoría (pantalla 1D)."""
    categoria: str
    mes: int
    anio: int
    total: float
    total_prev: float
    porcentaje_del_total: float
    desglose_comercio: list[MerchantBreakdown]
