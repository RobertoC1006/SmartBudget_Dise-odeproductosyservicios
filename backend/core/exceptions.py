"""
core/exceptions.py — Excepciones del dominio de SmartBudget+

¿Por qué definir excepciones propias?
  En lugar de lanzar excepciones genéricas (ValueError, Exception),
  usamos excepciones específicas del dominio. Esto permite que Fabián
  en api/routes/ capture exactamente qué falló y devuelva el código
  HTTP correcto con un mensaje claro al usuario de Flutter.

Jerarquía:
  SmartBudgetError (base)
  ├── SaldoInsuficienteError    → HTTP 422
  ├── MetaCompletadaError       → HTTP 409
  ├── MetaLimiteError           → HTTP 400
  ├── PresupuestoNoEncontradoError → HTTP 404
  ├── MetaNoEncontradaError     → HTTP 404
  ├── GastoNoEncontradoError    → HTTP 404
  ├── OCRFallidoError           → HTTP 422
  └── TokenInvalidoError        → HTTP 401

Uso en Fabián (api/routes/):
  try:
      resultado = core_function(db, user_id, ...)
  except SaldoInsuficienteError as e:
      raise HTTPException(status_code=422, detail=str(e))
"""


class SmartBudgetError(Exception):
    """
    Excepción base del dominio SmartBudget+.

    Todas las excepciones de negocio heredan de aquí.
    Esto permite capturar cualquier error del dominio con un solo except:

        except SmartBudgetError as e:
            # maneja cualquier error de negocio
    """
    pass


class SaldoInsuficienteError(SmartBudgetError):
    """
    Se lanza cuando el presupuesto disponible no alcanza para la operación.

    Situaciones:
    - El usuario intenta registrar un gasto mayor a su saldo disponible.
    - El usuario intenta aportar a una meta más dinero del que tiene.

    Fabián devuelve: HTTP 422 Unprocessable Entity
    Flutter muestra: "No tienes saldo suficiente. Disponible: S/. X.XX"
    """
    pass


class MetaCompletadaError(SmartBudgetError):
    """
    Se lanza cuando se intenta aportar dinero a una meta ya completada.

    Una meta completada tiene saldo_acumulado >= monto_objetivo.
    No tiene sentido seguir enviándole dinero (ya alcanzó el objetivo).

    Fabián devuelve: HTTP 409 Conflict
    Flutter muestra: "Esta meta ya fue completada. ¡Felicitaciones!"
    """
    pass


class MetaLimiteError(SmartBudgetError):
    """
    Se lanza cuando el usuario intenta crear más metas del límite permitido.

    El límite está definido en config.py como MAX_METAS_ACTIVAS (default: 10).
    Esto evita que un usuario tenga demasiadas metas activas sin gestionar.

    Fabián devuelve: HTTP 400 Bad Request
    Flutter muestra: "Alcanzaste el límite de X metas activas."
    """
    pass


class PresupuestoNoEncontradoError(SmartBudgetError):
    """
    Se lanza cuando el usuario no tiene un presupuesto creado para el mes actual.

    El usuario DEBE crear su presupuesto mensual manualmente antes de
    registrar gastos o aportar a metas. Si no lo ha hecho, esta excepción
    guía al usuario a crear su presupuesto primero.

    Fabián devuelve: HTTP 404 Not Found
    Flutter muestra: "No tienes presupuesto para este mes. ¡Crea uno!"
    """
    pass


class MetaNoEncontradaError(SmartBudgetError):
    """
    Se lanza cuando se busca una meta por ID y no existe o no pertenece al usuario.

    Importante: siempre verificar que goal.user_id == user_id para evitar
    que un usuario acceda a las metas de otro (seguridad por pertenencia).

    Fabián devuelve: HTTP 404 Not Found
    """
    pass


class GastoNoEncontradoError(SmartBudgetError):
    """
    Se lanza cuando se busca un gasto por ID y no existe o no pertenece al usuario.

    Igual que MetaNoEncontradaError, siempre validar la pertenencia.

    Fabián devuelve: HTTP 404 Not Found
    """
    pass


class OCRFallidoError(SmartBudgetError):
    """
    Se lanza cuando la IA no puede extraer datos confiables del archivo.

    Causas posibles:
    - La imagen está borrosa o tiene mala iluminación.
    - El PDF está protegido o es un scan de muy baja calidad.
    - La confianza del modelo es menor a 0.6 (umbral definido en core/ai.py).
    - El campo `monto` retornado por la IA es None o <= 0.

    Fabián devuelve: HTTP 422 Unprocessable Entity
    Flutter muestra: "No pudimos leer el ticket. Intenta con mejor iluminación."
    """
    pass


class TokenInvalidoError(SmartBudgetError):
    """
    Se lanza cuando el JWT es inválido, está expirado o fue manipulado.

    Causas posibles:
    - El token expiró (más de 24 horas desde el login).
    - El token fue alterado (firma inválida).
    - Se envió un token vacío o malformado.

    Fabián devuelve: HTTP 401 Unauthorized
    Flutter responde: borra el token almacenado y redirige al Login.
    """
    pass
