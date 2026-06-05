from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List
from core.enums import TipoAlerta

class AlertResponse(BaseModel):
    id: int
    user_id: int
    titulo: str
    mensaje: str
    tipo: TipoAlerta
    leida: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
