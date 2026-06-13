"""metas: columna recordatorio + tabla goal_contributions (historial de aportes)

Revision ID: b7e3a1f29c45
Revises: c2c155e74fc3
Create Date: 2026-06-12 10:00:00.000000

Cambios del rediseño del flujo de metas (Fase 0):
- Goal.recordatorio: si el usuario activó recordatorios (notificación local en Flutter).
- goal_contributions: historial de aportes para el gráfico de progreso real.
- Seed: por cada meta con saldo previo se inserta un aporte "semilla" con el
  monto acumulado y la fecha de creación de la meta, para que la suma de aportes
  cuadre con el saldo_acumulado y el gráfico no arranque incoherente.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b7e3a1f29c45'
down_revision: Union[str, None] = 'c2c155e74fc3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Esta migración es idempotente a propósito: la app crea el esquema con
    # Base.metadata.create_all() al arrancar (api/main.py), así que la columna o
    # la tabla pueden existir ya. Comprobamos antes de crear para que
    # `alembic upgrade head` funcione en cualquier estado.
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    goal_columns = {c["name"] for c in inspector.get_columns("goals")}
    tablas = set(inspector.get_table_names())

    # 1. Columna recordatorio en goals (server_default 0 para backfill de filas existentes)
    if "recordatorio" not in goal_columns:
        op.add_column(
            'goals',
            sa.Column('recordatorio', sa.Boolean(), nullable=False, server_default=sa.text('0')),
        )

    # 2. Tabla de historial de aportes
    if "goal_contributions" not in tablas:
        op.create_table(
            'goal_contributions',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('goal_id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('monto', sa.Numeric(precision=10, scale=2, asdecimal=False), nullable=False),
            sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
            sa.CheckConstraint('monto > 0', name='check_contribution_monto_positivo'),
            sa.ForeignKeyConstraint(['goal_id'], ['goals.id'], ondelete='CASCADE'),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id'),
        )
        op.create_index(op.f('ix_goal_contributions_goal_id'), 'goal_contributions', ['goal_id'], unique=False)
        op.create_index(op.f('ix_goal_contributions_user_id'), 'goal_contributions', ['user_id'], unique=False)
        op.create_index(op.f('ix_goal_contributions_created_at'), 'goal_contributions', ['created_at'], unique=False)

    # 3. Seed: aporte semilla por meta con saldo previo y sin aportes registrados
    #    (la suma de aportes queda igual al saldo_acumulado y el gráfico arranca coherente)
    op.execute(
        "INSERT INTO goal_contributions (goal_id, user_id, monto, created_at) "
        "SELECT g.id, g.user_id, g.saldo_acumulado, g.created_at FROM goals g "
        "WHERE g.saldo_acumulado > 0 "
        "AND NOT EXISTS (SELECT 1 FROM goal_contributions c WHERE c.goal_id = g.id)"
    )


def downgrade() -> None:
    op.drop_table('goal_contributions')
    op.drop_column('goals', 'recordatorio')
