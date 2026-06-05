from pydantic import BaseModel, Field, ConfigDict
from datetime import date, datetime
from typing import Optional
from core.enums import CategoriaGasto, FuenteGasto


class ExpenseCreate(BaseModel):
    categoria: CategoriaGasto
    monto: float = Field(gt=0)
    descripcion: Optional[str] = None
    comercio: Optional[str] = None
    fecha: date
    fuente: FuenteGasto = FuenteGasto.MANUAL


class ExpenseResponse(BaseModel):
    id: int
    categoria: str
    monto: float
    descripcion: Optional[str]
    comercio: Optional[str]
    fecha: date
    fuente: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ScanResponse(BaseModel):
    monto: Optional[float] = None
    fecha: Optional[str] = None
    categoria: Optional[str] = None
    descripcion: Optional[str] = None
    comercio: Optional[str] = None
    confianza: float
