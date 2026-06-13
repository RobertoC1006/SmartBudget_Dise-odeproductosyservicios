from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field

from core.enums import CategoriaMeta


class GoalCreate(BaseModel):
    nombre: str
    monto_objetivo: float = Field(..., gt=0)
    fecha_limite: Optional[date] = None
    categoria: Optional[CategoriaMeta] = None
    recordatorio: bool = False


class GoalUpdate(BaseModel):
    """
    Edición parcial de una meta. Los campos en None se dejan intactos, salvo
    `fecha_limite`, que se aplica siempre (permite limpiar la fecha objetivo).
    """
    nombre: Optional[str] = None
    monto_objetivo: Optional[float] = Field(default=None, gt=0)
    fecha_limite: Optional[date] = None
    categoria: Optional[CategoriaMeta] = None
    recordatorio: Optional[bool] = None


class GoalContribute(BaseModel):
    monto: float = Field(..., gt=0)


class ContributionResponse(BaseModel):
    """Un aporte del historial de una meta."""
    id: int
    monto: float
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class ContributeResult(BaseModel):
    """
    Resultado de un aporte: la meta actualizada más el impacto real en el
    SmartScore (delta entre el snapshot anterior y el recalculado tras el aporte).
    """
    id: int
    user_id: int
    nombre: str
    monto_objetivo: float
    saldo_acumulado: float
    fecha_limite: Optional[date] = None
    estado: str
    recordatorio: bool
    score_anterior: int
    score_nuevo: int
    score_delta: int

    model_config = ConfigDict(from_attributes=True)
