"""
core/analysis.py — Lógica del módulo de Análisis (rediseño 2026-06)

Responsabilidades (todo aditivo, no toca la lógica de gastos/presupuesto):
1. Resumen general del mes con comparativa contra el mes anterior (pantalla 1A).
2. Detalle de una categoría: total, comparativa y desglose POR COMERCIO (pantalla 1D).

Decisión de diseño (Roberto, 2026-06-14): el backend NO tiene subcategorías, así
que el desglose de una categoría se hace agrupando sus gastos por `comercio`.
Cuando un gasto no tiene comercio (registro manual), se usa su `descripcion`
como nombre; si tampoco hay descripción, cae a "Otros gastos" (ajuste 2026-06-24,
para no mostrar "Sin comercio").
"""

from sqlalchemy.orm import Session
from sqlalchemy import and_, extract, func

from db.models import Expense, Budget
from core.enums import CategoriaGasto

# Etiqueta de respaldo cuando un gasto no tiene comercio ni descripción.
ETIQUETA_GENERICA = "Otros gastos"


def _mes_anterior(mes: int, anio: int) -> tuple[int, int]:
    """Devuelve (mes, anio) del mes inmediatamente anterior."""
    if mes == 1:
        return 12, anio - 1
    return mes - 1, anio


def _gasto_total(db: Session, user_id: int, mes: int, anio: int) -> float:
    """Suma de todos los gastos del usuario en un mes/año."""
    total = db.query(func.sum(Expense.monto)).filter(
        and_(
            Expense.user_id == user_id,
            extract("month", Expense.fecha) == mes,
            extract("year", Expense.fecha) == anio,
        )
    ).scalar()
    return float(total) if total is not None else 0.0


def _gasto_categoria(db: Session, user_id: int, categoria: CategoriaGasto, mes: int, anio: int) -> float:
    """Suma de los gastos de una categoría en un mes/año."""
    total = db.query(func.sum(Expense.monto)).filter(
        and_(
            Expense.user_id == user_id,
            Expense.categoria == categoria,
            extract("month", Expense.fecha) == mes,
            extract("year", Expense.fecha) == anio,
        )
    ).scalar()
    return float(total) if total is not None else 0.0


def _ingresos(db: Session, user_id: int, mes: int, anio: int) -> float:
    """Ingresos del mes = monto_base + ingresos_adicionales del presupuesto de ese mes.

    Si el usuario no creó presupuesto para ese mes, devuelve 0.0.
    """
    budget = db.query(Budget).filter(
        and_(Budget.user_id == user_id, Budget.mes == mes, Budget.anio == anio)
    ).first()
    if budget is None:
        return 0.0
    return float(budget.monto_base + budget.ingresos_adicionales)


def desglose_por_comercio(
    db: Session, user_id: int, categoria: CategoriaGasto, mes: int, anio: int
) -> list[dict]:
    """Agrupa los gastos de una categoría por comercio, ordenados de mayor a menor.

    El nombre de cada grupo es el `comercio`; si el gasto no tiene comercio
    (registro manual), se usa su `descripcion`; si tampoco hay descripción, cae a
    "Otros gastos". Así no se muestra "Sin comercio" cuando hay un detalle útil.
    """
    filas = db.query(
        Expense.comercio,
        Expense.descripcion,
        Expense.monto,
    ).filter(
        and_(
            Expense.user_id == user_id,
            Expense.categoria == categoria,
            extract("month", Expense.fecha) == mes,
            extract("year", Expense.fecha) == anio,
        )
    ).all()

    acumulado: dict[str, dict] = {}
    for comercio, descripcion, monto in filas:
        # comercio → descripción → genérico (ignorando NULL y cadenas vacías).
        clave = (comercio or "").strip() or (descripcion or "").strip() or ETIQUETA_GENERICA
        registro = acumulado.setdefault(
            clave, {"comercio": clave, "total": 0.0, "n_transacciones": 0}
        )
        registro["total"] += float(monto) if monto is not None else 0.0
        registro["n_transacciones"] += 1

    desglose = list(acumulado.values())
    desglose.sort(key=lambda x: x["total"], reverse=True)
    return desglose


def resumen_overview(db: Session, user_id: int, mes: int, anio: int) -> dict:
    """Métricas de la pantalla 1A: gasto/ingresos/ahorro del mes + valores del mes anterior.

    Devuelve valores crudos; el cliente calcula los % de variación (evita divisiones
    por cero en el backend cuando el mes anterior no tiene datos).
    """
    pm, pa = _mes_anterior(mes, anio)

    gasto = _gasto_total(db, user_id, mes, anio)
    ingresos = _ingresos(db, user_id, mes, anio)
    gasto_prev = _gasto_total(db, user_id, pm, pa)
    ingresos_prev = _ingresos(db, user_id, pm, pa)

    return {
        "mes": mes,
        "anio": anio,
        "gasto_total": gasto,
        "ingresos": ingresos,
        "ahorro": ingresos - gasto,
        "gasto_total_prev": gasto_prev,
        "ingresos_prev": ingresos_prev,
        "ahorro_prev": ingresos_prev - gasto_prev,
    }


def detalle_categoria(
    db: Session, user_id: int, categoria: CategoriaGasto, mes: int, anio: int
) -> dict:
    """Datos de la pantalla 1D para una categoría: total, comparativa, % del total y desglose."""
    pm, pa = _mes_anterior(mes, anio)

    total = _gasto_categoria(db, user_id, categoria, mes, anio)
    total_prev = _gasto_categoria(db, user_id, categoria, pm, pa)
    gasto_mes = _gasto_total(db, user_id, mes, anio)
    porcentaje = round(total / gasto_mes * 100, 2) if gasto_mes > 0 else 0.0

    return {
        "categoria": categoria.value,
        "mes": mes,
        "anio": anio,
        "total": total,
        "total_prev": total_prev,
        "porcentaje_del_total": porcentaje,
        "desglose_comercio": desglose_por_comercio(db, user_id, categoria, mes, anio),
    }
