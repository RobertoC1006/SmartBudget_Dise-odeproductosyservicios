from pydantic import BaseModel, Field

class BudgetCreate(BaseModel):
    monto_base: float = Field(..., gt=0, description="Monto base del presupuesto")
    mes: int = Field(..., ge=1, le=12)
    año: int = Field(..., ge=2024)

class BudgetIncome(BaseModel):
    monto: float = Field(..., gt=0)
    descripcion: str
