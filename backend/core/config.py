"""
core/config.py — Configuración centralizada de SmartBudget+

¿Por qué pydantic-settings?
  - Lee el archivo .env automáticamente al importar `settings`.
  - Valida que todas las variables requeridas existan. Si falta alguna,
    la app NO arranca y lanza un error claro (fail-fast).
  - Convierte tipos automáticamente (ej: "1440" → int).
  - Permite valores por defecto para variables opcionales.

¿Por qué un singleton `settings`?
  Todos los módulos importan el MISMO objeto:
      from core.config import settings
  No se crea una instancia nueva cada vez — se reutiliza la misma.
  Esto garantiza consistencia y evita releer el .env múltiples veces.

Flujo:
  1. Docker pasa las variables via .env.docker
  2. Pydantic las lee y valida al importar
  3. Cualquier módulo de core/ accede via `settings.VARIABLE`
"""

from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    """
    Configuración completa de la aplicación.

    Variables REQUERIDAS (sin default → la app falla si no están):
      JWT_SECRET_KEY, OPENAI_API_KEY

    Variables OPCIONALES (tienen default → son configurables pero no obligatorias):
      Todas las demás.
    """

    # ─── App Info ────────────────────────────────────────────────────────────
    PROJECT_NAME: str = "SmartBudget+"
    BACKEND_CORS_ORIGINS: list[str] | str = ["*"]

    # ─── Seguridad JWT ──────────────────────────────────────────────────────
    JWT_SECRET_KEY: str
    """
    Clave secreta para firmar los tokens JWT.
    DEBE ser larga (mínimo 32 caracteres) y aleatoria.
    Si se cambia, todos los tokens existentes quedan inválidos (todos los
    usuarios tendrán que volver a hacer login).
    Genera una con: python -c "import secrets; print(secrets.token_hex(32))"
    """

    JWT_ALGORITHM: str = "HS256"
    """
    Algoritmo de firma del JWT.
    HS256 = HMAC con SHA-256. Estándar de la industria para APIs.
    No cambiar a menos que haya un requerimiento específico de seguridad.
    """

    JWT_EXPIRE_MINUTES: int = 1440
    """
    Tiempo de vida del token en minutos.
    1440 minutos = 24 horas.
    Después de este tiempo, Flutter deberá pedir al usuario que vuelva a
    hacer login (el token expirado lanzará TokenInvalidoError).
    """

    # ─── Base de Datos ───────────────────────────────────────────────────────
    DATABASE_URL: str = "mysql+pymysql://sb_user:sb_pass@mysql:3306/smartbudget_db"
    """
    URL de conexión a MySQL.
    Formato: mysql+pymysql://usuario:contraseña@host:puerto/nombre_bd
    
    En Docker: el host es "mysql" (nombre del servicio en docker-compose.yml)
    En local (sin Docker): sería "localhost"
    
    PyMySQL es el driver de Python para MySQL. Es puro Python, sin
    dependencias de sistema operativo (ideal para Docker).
    """

    # ─── OpenAI ──────────────────────────────────────────────────────────────
    OPENAI_API_KEY: str
    """
    API Key de OpenAI para el módulo de OCR (core/ai.py).
    Se obtiene en: https://platform.openai.com/api-keys
    NUNCA commitear este valor al repositorio.
    """

    OPENAI_MODEL: str = "gpt-4o"
    """
    Modelo de OpenAI a usar para extraer datos de tickets.
    gpt-4o es el modelo multimodal más avanzado (entiende imágenes y texto).
    Es más costoso que gpt-3.5 pero necesario para OCR preciso.
    """

    # ─── Moneda ──────────────────────────────────────────────────────────────
    MONEDA: str = "PEN"
    """
    Código ISO 4217 de la moneda.
    PEN = Sol Peruano. Fijo para esta versión de SmartBudget+.
    """

    SIMBOLO_MONEDA: str = "S/."
    """
    Símbolo visual de la moneda para mostrar en la app y en los mensajes.
    Ejemplo: "Tienes S/. 1,234.56 disponibles"
    """

    # ─── Límites del sistema ─────────────────────────────────────────────────
    MAX_METAS_ACTIVAS: int = 10
    """
    Máximo de metas en estado 'en_progreso' o 'pendiente' por usuario.
    Si se alcanza, crear_meta() lanza MetaLimiteError.
    Evita que usuarios creen metas sin límite y degraden el rendimiento.
    """

    OCR_CONFIANZA_MINIMA: float = 0.6
    """
    Umbral mínimo de confianza del OCR para aceptar el resultado.
    0.6 = 60% de confianza. Si la IA retorna menos, lanza OCRFallidoError.
    Un valor muy bajo aceptaría datos incorrectos; muy alto rechazaría tickets
    legítimos pero con poca calidad.
    """

    # ─── Configuración de Pydantic Settings ─────────────────────────────────
    model_config = SettingsConfigDict(
        env_file=".env",          # archivo .env local (desarrollo sin Docker)
        env_file_encoding="utf-8",
        case_sensitive=True,      # JWT_SECRET_KEY ≠ jwt_secret_key
        extra="ignore",           # ignora variables del .env que no estén definidas aquí
    )


@lru_cache()
def get_settings() -> Settings:
    """
    Devuelve la instancia única de Settings (patrón singleton con caché).

    @lru_cache() garantiza que Settings() se instancia UNA SOLA VEZ,
    sin importar cuántas veces se llame get_settings() en el código.

    Uso recomendado (para testing — permite sobreescribir settings):
        from core.config import get_settings
        settings = get_settings()

    Uso directo (para producción — más simple):
        from core.config import settings
    """
    return Settings()


# Instancia global lista para importar directamente
# Todos los módulos hacen: from core.config import settings
settings: Settings = get_settings()
