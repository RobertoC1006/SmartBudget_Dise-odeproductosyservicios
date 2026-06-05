"""
core/expenses.py — Lógica de gestión de gastos

Responsabilidades:
1. Registrar un gasto y descontarlo del presupuesto activo.
2. Eliminar un gasto y devolver el monto al presupuesto activo.
3. Listar los gastos de un mes específico.
4. Calcular el total gastado por categoría en un mes.
"""

from datetime import date
from sqlalchemy.orm import Session
from sqlalchemy import and_, extract, func

from db.models import Expense
from core.enums import CategoriaGasto, FuenteGasto
from core.exceptions import GastoNoEncontradoError
from core.budgets import descontar_gasto, revertir_gasto

def registrar_gasto(
    db: Session, 
    user_id: int, 
    categoria: CategoriaGasto, 
    monto: float, 
    descripcion: str | None,
    comercio: str | None, 
    fecha: date, 
    fuente: FuenteGasto = FuenteGasto.MANUAL
) -> Expense:
    """
    Registra un nuevo gasto y descuenta el dinero del presupuesto activo.
    
    Lanza:
    - SaldoInsuficienteError: Si el presupuesto no tiene fondos suficientes.
    - PresupuestoNoEncontradoError: Si no hay presupuesto activo.
    """
    # 1. Descontar del presupuesto (lanza excepciones si falla)
    descontar_gasto(db, user_id, monto)
    
    # 2. Registrar el gasto
    nuevo_gasto = Expense(
        user_id=user_id,
        categoria=categoria,
        monto=monto,
        descripcion=descripcion,
        comercio=comercio,
        fecha=fecha,
        fuente=fuente
    )
    
    db.add(nuevo_gasto)
    db.commit()
    db.refresh(nuevo_gasto)
    
    return nuevo_gasto

def eliminar_gasto(db: Session, user_id: int, expense_id: int) -> None:
    """
    Elimina un gasto y devuelve el dinero al presupuesto activo.
    
    Lanza:
    - GastoNoEncontradoError: Si el gasto no existe o no pertenece al usuario.
    """
    gasto = db.query(Expense).filter(
        and_(Expense.id == expense_id, Expense.user_id == user_id)
    ).first()
    
    if not gasto:
        raise GastoNoEncontradoError("El gasto no existe o no te pertenece.")
        
    # 1. Revertir el dinero al presupuesto
    revertir_gasto(db, user_id, gasto.monto)
    
    # 2. Eliminar el registro
    db.delete(gasto)
    db.commit()

def listar_gastos_mes(db: Session, user_id: int, mes: int, anio: int) -> list[Expense]:
    """
    Devuelve la lista de gastos realizados en un mes y año específicos.
    Se ordenan por fecha de manera descendente (los más recientes primero).
    """
    gastos = db.query(Expense).filter(
        and_(
            Expense.user_id == user_id,
            extract('month', Expense.fecha) == mes,
            extract('year', Expense.fecha) == anio
        )
    ).order_by(Expense.fecha.desc(), Expense.id.desc()).all()
    
    return gastos

def calcular_gastos_por_categoria(db: Session, user_id: int, mes: int, anio: int) -> dict:
    """
    Calcula cuánto se ha gastado en cada categoría durante un mes específico.
    Retorna un diccionario: {"comida": 320.0, "transporte": 150.0, ...}
    """
    resultados = db.query(
        Expense.categoria, 
        func.sum(Expense.monto).label("total")
    ).filter(
        and_(
            Expense.user_id == user_id,
            extract('month', Expense.fecha) == mes,
            extract('year', Expense.fecha) == anio
        )
    ).group_by(Expense.categoria).all()
    
    # Convertir el resultado de SQLAlchemy a un diccionario
    # resultados es una lista de tuplas: [(CategoriaGasto.COMIDA, 320.0), ...]
    resumen = {}
    for categoria, total in resultados:
        # Asegurarse de que el total no sea None (en SQLite/MySQL puede pasar)
        resumen[categoria.value] = float(total) if total is not None else 0.0
        
    return resumen
