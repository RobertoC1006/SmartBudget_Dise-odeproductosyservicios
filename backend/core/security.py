"""
core/security.py — Autenticación JWT y hashing de contraseñas

Este módulo es el guardián de la seguridad de SmartBudget+.
Implementa dos responsabilidades separadas:

1. HASHING DE CONTRASEÑAS (bcrypt):
   Las contraseñas NUNCA se guardan en texto plano en la BD.
   Se transforma en un hash irreversible antes de guardar.
   Al hacer login, se compara el hash (no se "descifra" la contraseña).

   ¿Por qué bcrypt y no SHA-256?
   - bcrypt es lento a propósito (cost factor), lo que dificulta
     los ataques de fuerza bruta (probar millones de combinaciones).
   - Genera un "salt" aleatorio automáticamente, evitando ataques
     de rainbow table (tablas precomputadas de hashes).

2. TOKENS JWT (JSON Web Tokens):
   Después del login exitoso, el servidor genera un token firmado.
   Flutter lo guarda de forma segura y lo envía en cada request.
   El servidor verifica la firma sin consultar la BD (stateless).

   Estructura del JWT:
   Header.Payload.Signature
   - Header: algoritmo (HS256)
   - Payload: {sub: "user_id", email: "...", exp: timestamp}
   - Signature: HMAC(header+payload, JWT_SECRET_KEY)
"""

from datetime import datetime, timedelta, timezone
from typing import Any

from jose import JWTError, jwt
from passlib.context import CryptContext

from core.config import settings
from core.exceptions import TokenInvalidoError


# ─── Contexto de hashing ────────────────────────────────────────────────────
# CryptContext gestiona el algoritmo de hashing.
# schemes=["bcrypt"] → usa bcrypt como algoritmo principal
# deprecated="auto" → si en el futuro se cambia el algoritmo, los hashes
#                     antiguos se marcan automáticamente como deprecados
#                     y se re-hashean en el próximo login del usuario.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ════════════════════════════════════════════════════════════════════════════
# SECCIÓN 1: Contraseñas
# ════════════════════════════════════════════════════════════════════════════

def obtener_password_hash(password: str) -> str:
    """
    Transforma una contraseña en texto plano a un hash bcrypt seguro.

    ¿Cuándo se usa?
    - En el registro del usuario: antes de guardar en la BD.
    - Al cambiar contraseña: antes de actualizar en la BD.

    Ejemplo:
        hash = obtener_password_hash("MiClave123!")
        # → "$2b$12$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"
        # El hash incluye el salt y el cost factor embebidos.

    Args:
        password: Contraseña en texto plano recibida del usuario.

    Returns:
        String del hash bcrypt (siempre diferente aunque sea la misma password,
        porque el salt es aleatorio cada vez).
    """
    return pwd_context.hash(password)


def verificar_password(password_plano: str, password_hash: str) -> bool:
    """
    Verifica si una contraseña en texto plano coincide con su hash.

    ¿Cómo funciona sin "descifrar"?
    bcrypt re-aplica el mismo proceso de hash usando el salt embebido
    en el hash almacenado y compara los resultados. Si coinciden → True.

    ¿Cuándo se usa?
    - En el login: comparar la contraseña ingresada con el hash en la BD.

    Ejemplo:
        es_valida = verificar_password("MiClave123!", hash_guardado_en_bd)
        # → True si la contraseña es correcta, False si no.

    Args:
        password_plano: Contraseña ingresada por el usuario en el login.
        password_hash: Hash almacenado en la BD (campo hashed_password de User).

    Returns:
        True si coinciden, False si no.
    """
    return pwd_context.verify(password_plano, password_hash)


# ════════════════════════════════════════════════════════════════════════════
# SECCIÓN 2: JSON Web Tokens (JWT)
# ════════════════════════════════════════════════════════════════════════════

def crear_token_acceso(data: dict[str, Any]) -> str:
    """
    Genera un JWT firmado con los datos del usuario.

    El token tiene una vida útil de JWT_EXPIRE_MINUTES minutos (default: 24h).
    Después de ese tiempo, decodificar_token() lanzará TokenInvalidoError
    y Flutter deberá redirigir al usuario al Login.

    ¿Qué va en el payload?
    - "sub" (subject): ID del usuario como string. Estándar RFC 7519.
    - "email": para información adicional (no re-consultar la BD).
    - "exp": timestamp Unix de expiración. jose lo verifica automáticamente.

    ¿Por qué usar timezone-aware datetime?
    timezone.utc evita bugs de zona horaria. El servidor puede estar en
    cualquier zona horaria, pero JWT siempre usa UTC.

    Uso (Fabián en routes/auth.py):
        token = crear_token_acceso({"sub": str(user.id), "email": user.email})
        return {"access_token": token, "token_type": "bearer"}

    Args:
        data: Diccionario con los datos a incluir en el payload del JWT.
              DEBE incluir "sub" con el user_id como string.

    Returns:
        Token JWT como string (formato: "eyJ...header.eyJ...payload.signature")
    """
    payload = data.copy()

    # Calcular el tiempo de expiración en UTC
    expiracion = datetime.now(timezone.utc) + timedelta(
        minutes=settings.JWT_EXPIRE_MINUTES
    )
    payload["exp"] = expiracion

    # Firmar el token con la clave secreta
    token = jwt.encode(
        payload,
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM
    )
    return token


def decodificar_token(token: str) -> dict[str, Any]:
    """
    Decodifica y valida un JWT, devolviendo su payload.

    Valida automáticamente:
    1. La firma (que no fue alterado el token).
    2. La expiración (campo "exp").
    Si alguna validación falla → lanza TokenInvalidoError.

    ¿Cuándo se usa?
    - En api/dependencies.py → get_current_user() para proteger endpoints.
    - Fabián llama esto en cada request autenticado.

    Uso (Fabián en dependencies.py):
        try:
            payload = decodificar_token(token)
            user_id = int(payload["sub"])
        except TokenInvalidoError:
            raise HTTPException(401, "Token inválido o expirado")

    Args:
        token: String del JWT recibido en el header "Authorization: Bearer <token>"

    Returns:
        Diccionario con el payload del token: {"sub": "42", "email": "...", "exp": ...}

    Raises:
        TokenInvalidoError: Si el token es inválido, expirado o malformado.
    """
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET_KEY,
            algorithms=[settings.JWT_ALGORITHM]
        )

        # Verificar que el payload tenga el campo "sub" (user_id)
        if payload.get("sub") is None:
            raise TokenInvalidoError("Token no contiene identificador de usuario")

        return payload

    except JWTError as e:
        # JWTError cubre: firma inválida, token expirado, formato incorrecto
        raise TokenInvalidoError(f"Token inválido: {str(e)}")
