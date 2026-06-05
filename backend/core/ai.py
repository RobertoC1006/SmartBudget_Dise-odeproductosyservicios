"""
core/ai.py — Módulo de Inteligencia Artificial (OCR)

Responsabilidades:
1. Recibir una imagen o PDF de un comprobante de pago.
2. Enviar el archivo a GPT-4o Vision.
3. Extraer los datos (monto, fecha, categoría, descripción, comercio).
4. Validar la confianza de la extracción.
"""

import base64
import json
from openai import AsyncOpenAI
from core.config import settings
from core.exceptions import OCRFallidoError
from core.enums import CategoriaGasto

# Inicializar cliente asíncrono de OpenAI
client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

# El prompt estricto que usaremos para garantizar el formato JSON de salida
OCR_PROMPT = """
Analiza esta imagen de un recibo, boleta, factura o ticket de compra y extrae los datos del gasto.
Devuelve ÚNICAMENTE un objeto JSON válido con este formato exacto, sin código markdown ni texto adicional:
{
  "monto": <número decimal en soles (float)>,
  "fecha": "<YYYY-MM-DD>",
  "categoria": "<comida|transporte|ocio|salud|educacion|ropa|hogar|tecnologia|viajes|otros>",
  "descripcion": "<descripción breve de los items comprados>",
  "comercio": "<nombre del negocio, local o empresa, o null si no se lee>",
  "confianza": <número entre 0.0 y 1.0 indicando qué tan seguro estás de la extracción>
}
Reglas estrictas:
1. Si no puedes determinar la categoría con certeza entre las opciones, usa "otros".
2. Si la fecha no es visible, usa null.
3. El campo monto debe ser un float (ejemplo: 12.50). Nunca uses comas para decimales, usa punto.
4. No inventes datos. Si algo es completamente ilegible, devuelve null en ese campo, pero intenta deducirlo por contexto.
"""

def _validar_resultado(data: dict) -> dict:
    """Aplica las reglas de negocio sobre el resultado crudo del OCR."""
    
    # Validar que el monto exista y sea positivo
    if data.get("monto") is None or float(data["monto"]) <= 0:
        raise OCRFallidoError("La IA no pudo detectar un monto válido en el comprobante.")
        
    # Validar el umbral de confianza definido en config.py
    confianza = float(data.get("confianza", 0))
    if confianza < settings.OCR_CONFIANZA_MINIMA:
        raise OCRFallidoError(f"La calidad de la imagen es baja (Confianza: {confianza*100:.0f}%). Por favor, intenta con una foto más clara.")

    # Validar categoría (asegurar que sea un valor del Enum)
    categoria_str = str(data.get("categoria", "")).lower()
    categorias_validas = [c.value for c in CategoriaGasto]
    
    if categoria_str not in categorias_validas:
        data["categoria"] = CategoriaGasto.OTROS.value
        
    return data

async def extraer_gasto_desde_imagen(image_bytes: bytes, content_type: str) -> dict:
    """
    Toma bytes de una imagen (JPG/PNG/WEBP), la envía a GPT-4o Vision y devuelve un dict validado.
    """
    # 1. Convertir bytes a base64
    base64_image = base64.b64encode(image_bytes).decode('utf-8')
    
    # 2. Llamar a OpenAI
    try:
        response = await client.chat.completions.create(
            model=settings.OPENAI_MODEL,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": OCR_PROMPT},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:{content_type};base64,{base64_image}",
                                "detail": "high"
                            }
                        }
                    ]
                }
            ],
            response_format={"type": "json_object"}, # Forza a GPT a devolver solo JSON
            max_tokens=500,
            temperature=0.0 # Temperatura 0 para resultados deterministas y precisos
        )
    except Exception as e:
        raise OCRFallidoError(f"Error de comunicación con OpenAI: {str(e)}")

    # 3. Parsear resultado
    try:
        json_str = response.choices[0].message.content
        resultado = json.loads(json_str)
    except Exception:
        raise OCRFallidoError("La IA devolvió un formato no válido.")

    # 4. Validar reglas de negocio
    return _validar_resultado(resultado)

async def extraer_gasto_desde_pdf(pdf_bytes: bytes) -> dict:
    """
    TODO: Lógica futura para leer PDFs.
    Requiere una librería adicional como PyMuPDF o pdf2image para extraer texto o 
    convertir el PDF a imágenes antes de enviarlo a GPT.
    Por ahora, Fabián bloqueará los PDFs en su endpoint o se puede simular.
    """
    raise NotImplementedError("La extracción desde PDF aún no está soportada en el Core.")
