"""
tests/test_security.py — Tests unitarios para core/security.py

Principios de testing aplicados:
- AAA Pattern: Arrange (preparar), Act (ejecutar), Assert (verificar)
- Tests independientes: cada test no depende del estado de otro
- Nombres descriptivos: test_<qué>_<condición>_<resultado_esperado>
- No se conecta a BD ni a servicios externos (tests puramente unitarios)

Para ejecutar:
    cd backend
    pytest tests/test_security.py -v

Para ejecutar todos los tests:
    pytest tests/ -v
"""

import pytest
from datetime import datetime, timezone

from core.security import (
    obtener_password_hash,
    verificar_password,
    crear_token_acceso,
    decodificar_token,
)
from core.exceptions import TokenInvalidoError


# ════════════════════════════════════════════════════════════════════════════
# Tests: Hashing de contraseñas
# ════════════════════════════════════════════════════════════════════════════

class TestHashingContrasenas:
    """Tests para las funciones de hashing bcrypt."""

    def test_obtener_password_hash_retorna_string(self):
        """El hash debe ser un string no vacío."""
        resultado = obtener_password_hash("MiClave123!")
        assert isinstance(resultado, str)
        assert len(resultado) > 0

    def test_obtener_password_hash_no_es_texto_plano(self):
        """El hash nunca debe ser igual a la contraseña original."""
        password = "MiClave123!"
        hash_result = obtener_password_hash(password)
        assert hash_result != password

    def test_obtener_password_hash_es_diferente_cada_vez(self):
        """
        bcrypt genera un salt aleatorio, por lo tanto el mismo password
        produce hashes diferentes en cada llamada.
        """
        password = "MiClave123!"
        hash1 = obtener_password_hash(password)
        hash2 = obtener_password_hash(password)
        assert hash1 != hash2

    def test_verificar_password_correcto_retorna_true(self):
        """La contraseña correcta debe verificarse exitosamente."""
        password = "MiClave123!"
        hash_guardado = obtener_password_hash(password)
        assert verificar_password(password, hash_guardado) is True

    def test_verificar_password_incorrecto_retorna_false(self):
        """Una contraseña incorrecta debe retornar False (no lanzar excepción)."""
        hash_guardado = obtener_password_hash("ClaveCorrecta")
        assert verificar_password("ClaveIncorrecta", hash_guardado) is False

    def test_verificar_password_vacio_retorna_false(self):
        """Una contraseña vacía nunca debe coincidir con un hash real."""
        hash_guardado = obtener_password_hash("AlgunaClaveReal")
        assert verificar_password("", hash_guardado) is False

    def test_hash_comienza_con_bcrypt_prefix(self):
        """El hash bcrypt siempre empieza con $2b$ (identificador del algoritmo)."""
        hash_result = obtener_password_hash("cualquier_password")
        assert hash_result.startswith("$2b$")


# ════════════════════════════════════════════════════════════════════════════
# Tests: JWT — Creación y decodificación
# ════════════════════════════════════════════════════════════════════════════

class TestJWT:
    """Tests para creación y decodificación de tokens JWT."""

    def test_crear_token_retorna_string_no_vacio(self):
        """El token debe ser un string no vacío."""
        token = crear_token_acceso({"sub": "1", "email": "test@test.com"})
        assert isinstance(token, str)
        assert len(token) > 0

    def test_token_tiene_tres_partes(self):
        """Un JWT válido tiene 3 partes separadas por puntos: header.payload.signature"""
        token = crear_token_acceso({"sub": "1", "email": "test@test.com"})
        partes = token.split(".")
        assert len(partes) == 3

    def test_decodificar_token_valido_retorna_payload(self):
        """Un token válido debe decodificarse y retornar el payload original."""
        data = {"sub": "42", "email": "usuario@smartbudget.com"}
        token = crear_token_acceso(data)
        payload = decodificar_token(token)

        assert payload["sub"] == "42"
        assert payload["email"] == "usuario@smartbudget.com"
        assert "exp" in payload  # la expiración debe estar en el payload

    def test_decodificar_token_invalido_lanza_excepcion(self):
        """Un token inventado/alterado debe lanzar TokenInvalidoError."""
        with pytest.raises(TokenInvalidoError):
            decodificar_token("esto.no.es.un.jwt.valido")

    def test_decodificar_token_vacio_lanza_excepcion(self):
        """Un token vacío debe lanzar TokenInvalidoError."""
        with pytest.raises(TokenInvalidoError):
            decodificar_token("")

    def test_decodificar_token_alterado_lanza_excepcion(self):
        """Modificar un byte del token debe invalidar la firma."""
        token = crear_token_acceso({"sub": "1"})
        # Alterar la sección de la firma para invalidarla de forma garantizada
        partes = token.split(".")
        partes[2] = partes[2][:-4] + "AAAA"
        token_alterado = ".".join(partes)
        with pytest.raises(TokenInvalidoError):
            decodificar_token(token_alterado)

    def test_token_contiene_campo_sub(self):
        """El payload del token siempre debe tener el campo 'sub'."""
        token = crear_token_acceso({"sub": "99"})
        payload = decodificar_token(token)
        assert "sub" in payload
        assert payload["sub"] == "99"

    def test_token_contiene_expiracion(self):
        """El token debe tener campo 'exp' con timestamp en el futuro."""
        token = crear_token_acceso({"sub": "1"})
        payload = decodificar_token(token)

        assert "exp" in payload
        # La expiración debe ser en el futuro
        ahora = datetime.now(timezone.utc).timestamp()
        assert payload["exp"] > ahora


# ════════════════════════════════════════════════════════════════════════════
# Tests: Enums
# ════════════════════════════════════════════════════════════════════════════

class TestEnums:
    """Tests para verificar que los enums tienen los valores correctos."""

    def test_categoria_gasto_tiene_todos_los_valores(self):
        """Verificar que están definidas las 10 categorías de gasto."""
        from core.enums import CategoriaGasto
        categorias = [c.value for c in CategoriaGasto]
        assert "comida" in categorias
        assert "transporte" in categorias
        assert "ocio" in categorias
        assert "salud" in categorias
        assert "educacion" in categorias
        assert "ropa" in categorias
        assert "hogar" in categorias
        assert "tecnologia" in categorias
        assert "viajes" in categorias
        assert "otros" in categorias
        assert len(categorias) == 10

    def test_enum_es_comparable_con_string(self):
        """Los enums heredan de str, por lo que pueden compararse con strings."""
        from core.enums import CategoriaGasto
        assert CategoriaGasto.COMIDA == "comida"
        assert CategoriaGasto.TRANSPORTE == "transporte"

    def test_estado_meta_tiene_cuatro_valores(self):
        """Verificar los 4 estados del ciclo de vida de una meta."""
        from core.enums import EstadoMeta
        estados = [e.value for e in EstadoMeta]
        assert "pendiente" in estados
        assert "en_progreso" in estados
        assert "completada" in estados
        assert "cancelada" in estados

    def test_tipo_alerta_tiene_cuatro_valores(self):
        """Verificar los 4 tipos de alerta."""
        from core.enums import TipoAlerta
        tipos = [t.value for t in TipoAlerta]
        assert "critica" in tipos
        assert "advertencia" in tipos
        assert "informativa" in tipos
        assert "motivacional" in tipos
