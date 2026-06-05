"""
core/enums.py — Vocabulario compartido de SmartBudget+

Este archivo define todas las constantes del dominio financiero de la app.
Es el ÚNICO lugar donde se definen estos valores — todos los demás módulos
(core/, api/, db/) los importan desde aquí.

¿Por qué heredar de (str, Enum)?
  - `str`: SQLAlchemy puede guardarlos como texto en la BD sin conversión.
  - `Enum`: Pydantic los valida automáticamente en los schemas de la API.
  - Ambos: se pueden comparar con strings normales ("comida" == CategoriaGasto.COMIDA).
"""

from enum import Enum


class CategoriaGasto(str, Enum):
    """
    Categorías disponibles para clasificar un gasto.

    Usada en:
    - db/models.py → campo `categoria` de Expense (guardado como texto)
    - api/schemas/expense.py → validación del campo en el request
    - core/smart_alerts.py → detectar patrones por categoría
    - core/simulator.py → simular reducción en categoría específica
    - core/ai.py → el prompt de OCR restringe las categorías a estos valores
    """
    COMIDA = "comida"
    TRANSPORTE = "transporte"
    OCIO = "ocio"
    SALUD = "salud"
    EDUCACION = "educacion"
    ROPA = "ropa"
    HOGAR = "hogar"
    TECNOLOGIA = "tecnologia"
    VIAJES = "viajes"
    OTROS = "otros"


class EstadoMeta(str, Enum):
    """
    Ciclo de vida de una meta de ahorro.

    PENDIENTE   → creada pero sin aportes aún
    EN_PROGRESO → tiene al menos un aporte registrado
    COMPLETADA  → saldo_acumulado >= monto_objetivo
    CANCELADA   → el usuario la abandonó (el dinero regresa al presupuesto)

    Usada en:
    - db/models.py → campo `estado` de Goal
    - core/goals.py → lógica de transición entre estados
    - core/smart_alerts.py → detectar metas próximas a completarse
    """
    PENDIENTE = "pendiente"
    EN_PROGRESO = "en_progreso"
    COMPLETADA = "completada"
    CANCELADA = "cancelada"


class FuenteGasto(str, Enum):
    """
    Cómo se originó el registro de un gasto.

    MANUAL    → el usuario ingresó los datos a mano
    OCR_IMAGEN → datos extraídos por IA desde una foto (JPG/PNG/WEBP)
    OCR_PDF   → datos extraídos por IA desde un archivo PDF

    Usada en:
    - db/models.py → campo `fuente` de Expense
    - core/ai.py → se asigna al crear el gasto desde OCR
    - api/routes/expenses.py → endpoint /scan asigna el valor correcto
    """
    MANUAL = "manual"
    OCR_IMAGEN = "ocr_imagen"
    OCR_PDF = "ocr_pdf"


class TipoAlerta(str, Enum):
    """
    Nivel de prioridad de una alerta del sistema.

    CRITICA      → acción urgente requerida (color rojo en Flutter)
    ADVERTENCIA  → situación de riesgo a vigilar (color amarillo)
    INFORMATIVA  → dato útil sin urgencia (color azul)
    MOTIVACIONAL → refuerzo positivo al usuario (color verde)

    El orden de prioridad para mostrar en Flutter:
    CRITICA > ADVERTENCIA > INFORMATIVA > MOTIVACIONAL

    Usada en:
    - db/models.py → campo `tipo` de Alert
    - core/smart_alerts.py → lógica de generación de alertas
    - api/routes/alerts.py → ordenar y filtrar alertas
    """
    CRITICA = "critica"
    ADVERTENCIA = "advertencia"
    INFORMATIVA = "informativa"
    MOTIVACIONAL = "motivacional"
