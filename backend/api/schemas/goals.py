from pydantic import BaseModel, Field

class GoalCreate(BaseModel):
    nombre: str
    monto_objetivo: float = Field(..., gt=0)

class GoalContribute(BaseModel):
    monto: float = Field(..., gt=0)
