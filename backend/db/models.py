"""
db/models.py — Definición de tablas de SmartBudget+ (SQLAlchemy 2.0)

Este archivo es el contrato entre Python y MySQL.
Usamos el estilo moderno de SQLAlchemy 2.0 para tener autocompletado perfecto
y tipado estricto.
"""

from datetime import datetime, date
from typing import List, Optional
from sqlalchemy import String, ForeignKey, Numeric, Integer, Enum as SQLEnum, Text, Date, DateTime, func, UniqueConstraint, CheckConstraint
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
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    
    mes: Mapped[int] = mapped_column(Integer, index=True) # 1-12
    anio: Mapped[int] = mapped_column(Integer, index=True)
    
    monto_base: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False), default=0.0)
    ingresos_adicionales: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False), default=0.0)
    total_gastado: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False), default=0.0)
    
    # Saldo que el usuario tiene para gastar o ahorrar hoy.
    # Se calcula como: (monto_base + ingresos_adicionales) - total_gastado - aportes_metas
    # Puede ser negativo en caso de sobregiro.
    saldo_disponible: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False), default=0.0)

    # Relaciones
    user: Mapped["User"] = relationship(back_populates="budgets")
    income_logs: Mapped[List["IncomeLog"]] = relationship(back_populates="budget", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("user_id", "mes", "anio", name="uq_user_budget_mes_anio"),
        CheckConstraint("monto_base >= 0", name="check_budget_monto_base_positivo"),
        CheckConstraint("ingresos_adicionales >= 0", name="check_budget_ingresos_adicionales_positivo"),
        CheckConstraint("total_gastado >= 0", name="check_budget_total_gastado_positivo"),
    )

class IncomeLog(Base):
    """Registro histórico de ingresos adicionales."""
    __tablename__ = "income_logs"
    
    id: Mapped[int] = mapped_column(primary_key=True)
    budget_id: Mapped[int] = mapped_column(ForeignKey("budgets.id", ondelete="CASCADE"))
    monto: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False))
    descripcion: Mapped[str] = mapped_column(String(200))
    fecha: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    budget: Mapped["Budget"] = relationship(back_populates="income_logs")

    __table_args__ = (
        CheckConstraint("monto > 0", name="check_income_monto_positivo"),
    )

class Goal(Base):
    """Metas de ahorro."""
    __tablename__ = "goals"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    
    nombre: Mapped[str] = mapped_column(String(150))
    descripcion: Mapped[Optional[str]] = mapped_column(Text)
    monto_objetivo: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False))
    saldo_acumulado: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False), default=0.0)
    
    fecha_limite: Mapped[Optional[date]] = mapped_column(Date)
    estado: Mapped[EstadoMeta] = mapped_column(SQLEnum(EstadoMeta), default=EstadoMeta.PENDIENTE, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="goals")

    __table_args__ = (
        CheckConstraint("monto_objetivo > 0", name="check_goal_monto_objetivo_positivo"),
        CheckConstraint("saldo_acumulado >= 0", name="check_goal_saldo_acumulado_positivo"),
    )

class Expense(Base):
    """Gastos registrados."""
    __tablename__ = "expenses"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    
    categoria: Mapped[CategoriaGasto] = mapped_column(SQLEnum(CategoriaGasto), index=True)
    monto: Mapped[float] = mapped_column(Numeric(10, 2, asdecimal=False))
    descripcion: Mapped[Optional[str]] = mapped_column(String(255))
    comercio: Mapped[Optional[str]] = mapped_column(String(150))
    
    fecha: Mapped[date] = mapped_column(Date, index=True)
    fuente: Mapped[FuenteGasto] = mapped_column(SQLEnum(FuenteGasto), default=FuenteGasto.MANUAL)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="expenses")

    __table_args__ = (
        CheckConstraint("monto > 0", name="check_expense_monto_positivo"),
    )

class Alert(Base):
    """Alertas del sistema."""
    __tablename__ = "alerts"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    
    titulo: Mapped[str] = mapped_column(String(100))
    mensaje: Mapped[str] = mapped_column(Text)
    tipo: Mapped[TipoAlerta] = mapped_column(SQLEnum(TipoAlerta), index=True)
    leida: Mapped[bool] = mapped_column(default=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), index=True)

class SmartScoreSnapshot(Base):
    """Historial de SmartScore por mes."""
    __tablename__ = "smart_score_history"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    score: Mapped[int] = mapped_column(Integer) # 0-100
    mes: Mapped[int] = mapped_column(Integer, index=True)
    anio: Mapped[int] = mapped_column(Integer, index=True)
    fecha_calculo: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    __table_args__ = (
        UniqueConstraint("user_id", "mes", "anio", name="uq_user_score_mes_anio"),
        CheckConstraint("score >= 0 AND score <= 100", name="check_score_rango_valido"),
    )
