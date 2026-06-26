from typing import Optional
from pydantic import BaseModel


class ProfileSummaryResponse(BaseModel):
    """Métricas reales del 'Resumen personal' de la pantalla de Perfil (1A)."""
    metas_activas: int
    gastos_registrados: int
    dinero_ahorrado: float
    smartscore: Optional[int] = None
    smartscore_delta: int = 0
