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
