from pydantic import BaseModel, Field
from typing import List, Optional

class ImpactoMeta(BaseModel):
    nombre: str
    monto_objetivo: float
    saldo_acumulado: float
    faltante_actual: float
    porcentaje_comprometido: float

class SimulationRequest(BaseModel):
    monto_compra: float = Field(..., gt=0, description="Monto de la compra a simular")

class SimulationResponse(BaseModel):
    compra_viable: bool
    saldo_proyectado: float
    porcentaje_saldo_consumido: float
    impacto_metas: List[ImpactoMeta]
    mensaje_analisis: str
    nivel_riesgo: str

# ─── Sim Fase 1: Micro-ahorro Progresivo ─────────────────────────────────────

class SavingsProjectionRequest(BaseModel):
    categoria: str = Field(..., description="Categoría de gasto a reducir")
    gasto_actual_mensual: float = Field(..., gt=0, description="Gasto actual mensual en esa categoría")
    gasto_objetivo_mensual: float = Field(..., ge=0, description="Gasto objetivo mensual (menor al actual)")

class MetaImpactoAhorro(BaseModel):
    nombre: str
    monto_objetivo: float
    saldo_acumulado: float
    faltante: float
    meses_para_completar: Optional[float]
    porcentaje_cubierto_12m: float

class SavingsProjectionResponse(BaseModel):
    categoria: str
    ahorro_mensual: float
    ahorro_semanal: float
    proyeccion_3m: float
    proyeccion_6m: float
    proyeccion_12m: float
    meta_impacto: List[MetaImpactoAhorro]
    mensaje: str
