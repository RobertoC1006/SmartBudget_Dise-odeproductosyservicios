from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional

class ScoreResponse(BaseModel):
    score: int

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
