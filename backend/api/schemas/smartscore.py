from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class ScoreDesglose(BaseModel):
    """Puntos que aporta cada criterio al SmartScore total."""
    presupuesto: int
    metas: int
    alertas: int
    ahorro: int

class ScoreResponse(BaseModel):
    score: int
    desglose: Optional[ScoreDesglose] = None

class SnapshotResponse(BaseModel):
    id: int
    user_id: int
    score: int
    mes: int
    anio: int
    fecha_calculo: datetime

    model_config = ConfigDict(from_attributes=True)

class SnapshotHistoryResponse(BaseModel):
    id: int
    score: int
    mes: int
    anio: int
    fecha_calculo: Optional[str] = None
