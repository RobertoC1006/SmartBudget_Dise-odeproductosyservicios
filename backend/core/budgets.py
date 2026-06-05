"""
core/budgets.py — Lógica de gestión de presupuestos mensuales e ingresos adicionales

Responsabilidades:
1. Crear presupuestos para un mes específico.
2. Recuperar el presupuesto activo.
3. Registrar ingresos extras y actualizar saldos.
4. Calcular el resumen para el Dashboard de Flutter.
"""

from datetime import date
from sqlalchemy.orm import Session
from sqlalchemy import and_

from db.models import Budget, IncomeLog
from core.exceptions import PresupuestoNoEncontradoError, SaldoInsuficienteError

def obtener_presupuesto_activo(db: Session, user_id: int) -> Budget:
    """
    Busca el presupuesto del usuario para el mes y año actuales.
    
    Lanza PresupuestoNoEncontradoError si el usuario aún no lo ha creado.
    Esto obliga a Fabián a capturar el error y a Flutter a mostrar
    la pantalla de "Crea tu presupuesto del mes".
    """
    hoy = date.today()
    budget = db.query(Budget).filter(
        and_(
            Budget.user_id == user_id,
            Budget.mes == hoy.month,
            Budget.anio == hoy.year
        )
    ).first()

    if not budget:
        raise PresupuestoNoEncontradoError(
            f"No se encontró un presupuesto activo para {hoy.month}/{hoy.year}"
        )
    
    return budget

def crear_presupuesto_mes(db: Session, user_id: int, monto_base: float, mes: int, anio: int) -> Budget:
    """
    Crea un nuevo presupuesto. Si ya existe uno para ese mes, lo actualiza.
    
    Args:
        monto_base: El presupuesto inicial que el usuario ingresa (ej: su sueldo).
    """
    # Verificar si ya existe uno
    budget = db.query(Budget).filter(
        and_(
            Budget.user_id == user_id,
            Budget.mes == mes,
            Budget.anio == anio
        )
    ).first()

    if budget:
        # Si ya existe, actualizamos el monto base y recalculamos el disponible
        diferencia = monto_base - budget.monto_base
        budget.monto_base = monto_base
        budget.saldo_disponible += diferencia
    else:
        # Si es nuevo, el disponible inicial es igual al monto base
        budget = Budget(
            user_id=user_id,
            mes=mes,
            anio=anio,
            monto_base=monto_base,
            saldo_disponible=monto_base
        )
        db.add(budget)

    db.commit()
    db.refresh(budget)
    return budget

def agregar_ingreso_adicional(db: Session, user_id: int, monto: float, descripcion: str) -> Budget:
    """
    Registra una entrada de dinero extra (ej: un bono, una venta).
    
    Actualiza automáticamente el saldo_disponible del presupuesto del mes actual.
    """
    budget = obtener_presupuesto_activo(db, user_id)

    # 1. Crear el log histórico
    log = IncomeLog(
        budget_id=budget.id,
        monto=monto,
        descripcion=descripcion
    )
    db.add(log)

    # 2. Actualizar el presupuesto
    budget.ingresos_adicionales += monto
    budget.saldo_disponible += monto

    db.commit()
    db.refresh(budget)
    return budget

def calcular_resumen_mensual(db: Session, user_id: int) -> dict:
    """
    Prepara los datos exactos que Fabián necesita para el Dashboard.
    
    Retorna un diccionario con porcentajes y montos listos para las gráficas.
    """
    budget = obtener_presupuesto_activo(db, user_id)
    
    total_ingresos = budget.monto_base + budget.ingresos_adicionales
    porcentaje_gastado = (budget.total_gastado / total_ingresos * 100) if total_ingresos > 0 else 0

    return {
        "saldo_disponible": budget.saldo_disponible,
        "total_gastado": budget.total_gastado,
        "monto_base": budget.monto_base,
        "ingresos_adicionales": budget.ingresos_adicionales,
        "porcentaje_gastado": round(porcentaje_gastado, 2),
        "mes": budget.mes,
        "anio": budget.anio,
        "simbolo": "S/."
    }

def descontar_gasto(db: Session, user_id: int, monto: float) -> Budget:
    """
    Descuenta el monto del saldo disponible del presupuesto activo.
    """
    budget = obtener_presupuesto_activo(db, user_id)
    if budget.saldo_disponible < monto:
        raise SaldoInsuficienteError(
            f"No tienes saldo suficiente en tu presupuesto mensual. Disponible: S/. {budget.saldo_disponible:.2f}"
        )
    
    budget.saldo_disponible -= monto
    budget.total_gastado += monto
    db.commit()
    db.refresh(budget)
    return budget

def revertir_gasto(db: Session, user_id: int, monto: float) -> Budget:
    """
    Revierte un gasto, devolviendo el monto al saldo disponible.
    """
    budget = obtener_presupuesto_activo(db, user_id)
    budget.saldo_disponible += monto
    budget.total_gastado -= monto
    db.commit()
    db.refresh(budget)
    return budget
