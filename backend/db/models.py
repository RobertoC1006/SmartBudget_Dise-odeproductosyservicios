"""
db/models.py — Definición de tablas de SmartBudget+ (SQLAlchemy 2.0)

Este archivo es el contrato entre Python y MySQL.
Usamos el estilo moderno de SQLAlchemy 2.0 para tener autocompletado perfecto
y tipado estricto.
"""

from datetime import datetime, date
from typing import List, Optional
from sqlalchemy import String, ForeignKey, Float, Integer, Enum as SQLEnum, Text, Date, DateTime, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

from core.enums import CategoriaGasto, EstadoMeta, FuenteGasto, TipoAlerta

class Base(DeclarativeBase):
    """Clase base de la que heredan todos los modelos."""
    pass

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(150), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    # Relaciones
    budgets: Mapped[List["Budget"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    goals: Mapped[List["Goal"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    expenses: Mapped[List["Expense"]] = relationship(back_populates="user", cascade="all, delete-orphan")

class Budget(Base):
    """
    Representa el presupuesto de un usuario para un mes específico.
    Es la fuente principal de saldo disponible.
    """
    __tablename__ = "budgets"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    
    mes: Mapped[int] = mapped_column(Integer) # 1-12
    anio: Mapped[int] = mapped_column(Integer)
    
    monto_base: Mapped[float] = mapped_column(Float, default=0.0)
    ingresos_adicionales: Mapped[float] = mapped_column(Float, default=0.0)
    total_gastado: Mapped[float] = mapped_column(Float, default=0.0)
    
    # Saldo que el usuario tiene para gastar o ahorrar hoy.
    # Se calcula como: (monto_base + ingresos_adicionales) - total_gastado - aportes_metas
    saldo_disponible: Mapped[float] = mapped_column(Float, default=0.0)

    # Relaciones
    user: Mapped["User"] = relationship(back_populates="budgets")
    income_logs: Mapped[List["IncomeLog"]] = relationship(back_populates="budget")

class IncomeLog(Base):
    """Registro histórico de ingresos adicionales."""
    __tablename__ = "income_logs"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    budget_id: Mapped[int] = mapped_column(ForeignKey("budgets.id"))
    monto: Mapped[float] = mapped_column(Float)
    descripcion: Mapped[str] = mapped_column(String(200))
    fecha: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    budget: Mapped["Budget"] = relationship(back_populates="income_logs")

class Goal(Base):
    """Metas de ahorro."""
    __tablename__ = "goals"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    
    nombre: Mapped[str] = mapped_column(String(150))
    descripcion: Mapped[Optional[str]] = mapped_column(Text)
    monto_objetivo: Mapped[float] = mapped_column(Float)
    saldo_acumulado: Mapped[float] = mapped_column(Float, default=0.0)
    
    fecha_limite: Mapped[Optional[date]] = mapped_column(Date)
    estado: Mapped[EstadoMeta] = mapped_column(SQLEnum(EstadoMeta), default=EstadoMeta.PENDIENTE)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="goals")

class Expense(Base):
    """Gastos registrados."""
    __tablename__ = "expenses"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    
    categoria: Mapped[CategoriaGasto] = mapped_column(SQLEnum(CategoriaGasto))
    monto: Mapped[float] = mapped_column(Float)
    descripcion: Mapped[Optional[str]] = mapped_column(String(255))
    comercio: Mapped[Optional[str]] = mapped_column(String(150))
    
    fecha: Mapped[date] = mapped_column(Date)
    fuente: Mapped[FuenteGasto] = mapped_column(SQLEnum(FuenteGasto), default=FuenteGasto.MANUAL)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="expenses")

class Alert(Base):
    """Alertas del sistema."""
    __tablename__ = "alerts"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    
    titulo: Mapped[str] = mapped_column(String(100))
    mensaje: Mapped[str] = mapped_column(Text)
    tipo: Mapped[TipoAlerta] = mapped_column(SQLEnum(TipoAlerta))
    leida: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

class SmartScoreSnapshot(Base):
    """Historial de SmartScore por mes."""
    __tablename__ = "smart_score_history"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    score: Mapped[int] = mapped_column(Integer) # 0-100
    mes: Mapped[int] = mapped_column(Integer)
    anio: Mapped[int] = mapped_column(Integer)
    fecha_calculo: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
