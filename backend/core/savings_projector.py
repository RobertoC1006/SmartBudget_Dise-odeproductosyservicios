"""
core/savings_projector.py — Proyector de Micro-ahorro Progresivo (Stateless)

Responde: "¿Qué pasa si gasto S/X menos en esta categoría?"
Calcula proyecciones a 3, 6 y 12 meses y el impacto en metas activas.
"""

from typing import List, Dict, Any, Optional


def calcular_proyeccion_ahorro(
    categoria: str,
    gasto_actual_mensual: float,
    gasto_objetivo_mensual: float,
    metas_activas: List[Dict[str, Any]],
) -> Dict[str, Any]:
    """
    Proyecta el ahorro acumulado al reducir el gasto en una categoría.

    Args:
        categoria: Nombre de la categoría (comida, transporte, etc.)
        gasto_actual_mensual: Cuánto gasta actualmente al mes en esa categoría.
        gasto_objetivo_mensual: Cuánto quiere gastar al mes (debe ser menor al actual).
        metas_activas: Lista de metas con 'nombre', 'monto_objetivo', 'saldo_acumulado'.

    Returns:
        Diccionario con ahorro mensual, semanal, proyecciones 3/6/12m e impacto en metas.
    """
    ahorro_mensual = gasto_actual_mensual - gasto_objetivo_mensual

    if ahorro_mensual <= 0:
        return {
            "categoria": categoria,
            "ahorro_mensual": 0.0,
            "ahorro_semanal": 0.0,
            "proyeccion_3m": 0.0,
            "proyeccion_6m": 0.0,
            "proyeccion_12m": 0.0,
            "meta_impacto": [],
            "mensaje": (
                f"El monto objetivo debe ser menor al gasto actual para proyectar ahorro. "
                f"Ajusta el objetivo por debajo de S/ {gasto_actual_mensual:.0f}."
            ),
        }

    ahorro_semanal = ahorro_mensual / 4.33
    proyeccion_3m = round(ahorro_mensual * 3, 2)
    proyeccion_6m = round(ahorro_mensual * 6, 2)
    proyeccion_12m = round(ahorro_mensual * 12, 2)

    meta_impacto = []
    for meta in metas_activas:
        nombre = meta.get("nombre", "Meta")
        monto_objetivo = meta.get("monto_objetivo", 0.0)
        saldo_acumulado = meta.get("saldo_acumulado", 0.0)
        faltante = max(0.0, monto_objetivo - saldo_acumulado)

        if faltante <= 0:
            continue

        meses_para_completar: Optional[float] = round(faltante / ahorro_mensual, 1)
        porcentaje_cubierto_12m = round(min(100.0, (proyeccion_12m / faltante) * 100), 1)

        meta_impacto.append({
            "nombre": nombre,
            "monto_objetivo": monto_objetivo,
            "saldo_acumulado": saldo_acumulado,
            "faltante": round(faltante, 2),
            "meses_para_completar": meses_para_completar,
            "porcentaje_cubierto_12m": porcentaje_cubierto_12m,
        })

    # Mensaje dinámico según magnitud del ahorro
    reduccion_pct = (ahorro_mensual / gasto_actual_mensual) * 100
    categoria_label = categoria.capitalize()

    if reduccion_pct >= 30:
        tono = f"¡Excelente decisión! Reducir {categoria_label} en un {reduccion_pct:.0f}% genera un impacto real."
    elif reduccion_pct >= 15:
        tono = f"Buen hábito. Reducir {categoria_label} en un {reduccion_pct:.0f}% es sostenible a largo plazo."
    else:
        tono = f"Pequeño ahorro pero constante. Cada sol cuenta en {categoria_label}."

    mensaje = (
        f"{tono} "
        f"Ahorrando S/ {ahorro_mensual:.0f} al mes, "
        f"en 12 meses acumularás S/ {proyeccion_12m:.0f}."
    )

    return {
        "categoria": categoria,
        "ahorro_mensual": round(ahorro_mensual, 2),
        "ahorro_semanal": round(ahorro_semanal, 2),
        "proyeccion_3m": proyeccion_3m,
        "proyeccion_6m": proyeccion_6m,
        "proyeccion_12m": proyeccion_12m,
        "meta_impacto": meta_impacto,
        "mensaje": mensaje,
    }
