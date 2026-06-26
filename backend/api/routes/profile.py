from fastapi import APIRouter, Depends

from api.dependencies import get_db, get_current_user
from api.schemas.profile import ProfileSummaryResponse
from core import profile as profile_core

router = APIRouter()


@router.get("/summary", response_model=ProfileSummaryResponse)
def summary(db=Depends(get_db), user=Depends(get_current_user)):
    """Métricas reales del 'Resumen personal' de la pantalla de Perfil (1A)."""
    return profile_core.obtener_resumen_perfil(db, user.id)
