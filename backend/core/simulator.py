"""
core/simulator.py — Simulador de Compras Inteligente (Stateless)

Este módulo es una herramienta de asesoría financiera matemática. Es stateless (sin base de datos)
para garantizar velocidad, testeabilidad absoluta y facilidad de uso desde cualquier endpoint.

Responsabilidad principal:
- Evaluar la viabilidad de una compra basándose en el saldo disponible del usuario y
  estimar el impacto inmediato en sus metas de ahorro activas.
"""

from typing import List, Dict, Any

def simular_compra(
    saldo_disponible: float, 
    monto_compra: float, 
    metas_activas: List[Dict[str, Any]]
) -> Dict[str, Any]:
    """
    Simula la compra de un producto/servicio y analiza el impacto financiero.
    
    Args:
        saldo_disponible: Dinero libre que el usuario tiene en su presupuesto mensual actual.
        monto_compra: Costo estimado de la compra que el usuario quiere realizar.
        metas_activas: Lista de diccionarios con las metas en progreso del usuario.
                       Formato esperado:
                       [
                           {"nombre": "Bicicleta", "monto_objetivo": 1000.0, "saldo_acumulado": 400.0, "faltante": 600.0},
                           ...
                       ]
                       
    Returns:
        Diccionario detallado con viabilidad, saldo proyectado e impacto en metas.
    """
    # 1. Validaciones básicas
    if monto_compra <= 0:
        return {
            "compra_viable": False,
            "saldo_proyectado": saldo_disponible,
            "porcentaje_saldo_consumido": 0.0,
            "impacto_metas": [],
            "mensaje_analisis": "El monto de la compra debe ser mayor a cero para poder realizar la simulación.",
            "nivel_riesgo": "bajo"
        }
        
    if saldo_disponible <= 0:
        return {
            "compra_viable": False,
            "saldo_proyectado": 0.0,
            "porcentaje_saldo_consumido": 0.0,
            "impacto_metas": [],
            "mensaje_analisis": "No tienes saldo disponible en tu presupuesto mensual actual. ¡Es recomendable crear tu presupuesto o registrar un ingreso adicional primero!",
            "nivel_riesgo": "critico"
        }

    # 2. Análisis de Viabilidad
    saldo_proyectado = saldo_disponible - monto_compra
    porcentaje_consumido = (monto_compra / saldo_disponible) * 100
    compra_viable = saldo_proyectado >= 0

    if not compra_viable:
        return {
            "compra_viable": False,
            "saldo_proyectado": saldo_proyectado,
            "porcentaje_saldo_consumido": porcentaje_consumido,
            "impacto_metas": [],
            "mensaje_analisis": f"Compra INVILABLE. El costo de la compra (S/. {monto_compra:.2f}) excede tu saldo disponible actual (S/. {saldo_disponible:.2f}) por S/. {abs(saldo_proyectado):.2f}.",
            "nivel_riesgo": "critico"
        }

    # 3. Análisis de Impacto en Metas
    # Si hay saldo disponible y la compra es viable, evaluamos cómo afecta la capacidad de ahorro.
    # El dinero gastado en la compra es dinero que ya no se puede aportar a las metas.
    impacto_metas = []
    riesgo = "bajo"
    
    # Calcular el total faltante de ahorro
    total_faltante_ahorro = sum(m.get("faltante", max(0.0, m.get("monto_objetivo", 0.0) - m.get("saldo_acumulado", 0.0))) for m in metas_activas)
    
    for meta in metas_activas:
        nombre = meta.get("nombre", "Meta sin nombre")
        monto_objetivo = meta.get("monto_objetivo", 0.0)
        saldo_acumulado = meta.get("saldo_acumulado", 0.0)
        faltante = meta.get("faltante", max(0.0, monto_objetivo - saldo_acumulado))
        
        # Simular conflicto:
        # Si el saldo proyectado es menor que el total faltante de las metas de ahorro,
        # hay una competencia directa de recursos. 
        # Si compramos, ¿nos queda menos del 15% del objetivo de la meta en saldo de seguridad?
        porcentaje_comprometido = 0.0
        if saldo_proyectado < total_faltante_ahorro and total_faltante_ahorro > 0:
            # Proporción del gasto que 'afecta' teóricamente a esta meta en la distribución de recursos restantes
            porcentaje_comprometido = (monto_compra / total_faltante_ahorro) * 100
            
        impacto_metas.append({
            "nombre": nombre,
            "monto_objetivo": monto_objetivo,
            "saldo_acumulado": saldo_acumulado,
            "faltante_actual": faltante,
            "porcentaje_comprometido": round(min(100.0, porcentaje_comprometido), 2)
        })

    # Determinar el nivel de riesgo financiero de la compra
    if porcentaje_consumido > 75:
        riesgo = "critico"
        mensaje_analisis = (
            f"La compra es VIABLE pero ALTAMENTE RIESGOSA. Consumirá el {porcentaje_consumido:.1f}% de tu presupuesto "
            f"disponible, dejándote con solo S/. {saldo_proyectado:.2f} para emergencias. Se recomienda posponerla."
        )
    elif porcentaje_consumido > 40:
        riesgo = "medio"
        mensaje_analisis = (
            f"Compra viable con riesgo MEDIO. Consumirá el {porcentaje_consumido:.1f}% de tu saldo disponible. "
            f"Aún te quedarán S/. {saldo_proyectado:.2f}. Si tienes metas de ahorro activas, es posible que "
            f"tardes un poco más en completarlas."
        )
    else:
        riesgo = "bajo"
        mensaje_analisis = (
            f"¡Compra viable y SEGURA! Consumirá solo el {porcentaje_consumido:.1f}% de tu saldo disponible. "
            f"Mantienes una excelente salud financiera con S/. {saldo_proyectado:.2f} restantes."
        )

    # Si hay metas y la compra es viable pero nos deja con menos dinero que el ahorro faltante
    if metas_activas and saldo_proyectado < total_faltante_ahorro and riesgo == "bajo":
        riesgo = "medio"
        mensaje_analisis += " Nota: Tus fondos proyectados son menores que tus metas de ahorro pendientes. ¡Gasta con moderación!"

    return {
        "compra_viable": True,
        "saldo_proyectado": round(saldo_proyectado, 2),
        "porcentaje_saldo_consumido": round(porcentaje_consumido, 2),
        "impacto_metas": impacto_metas,
        "mensaje_analisis": mensaje_analisis,
        "nivel_riesgo": riesgo
    }
