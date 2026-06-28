"""aportes: columnas fecha + descripcion en goal_contributions

Revision ID: e1a7c9d4f206
Revises: c4d8e2a17b93
Create Date: 2026-06-25 12:00:00.000000

Rediseño del flujo de aporte a meta (Fase 0):
- goal_contributions.fecha: fecha del aporte elegida por el usuario (default hoy).
  El gráfico de progreso pasa a agrupar por esta fecha. Backfill de filas
  existentes con DATE(created_at) para no romper el acumulado.
- goal_contributions.descripcion: nota opcional del aporte.

Idempotente: convive con `Base.metadata.create_all()` (comprueba columnas antes
de crear), igual que las migraciones de metas.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e1a7c9d4f206'
down_revision: Union[str, None] = 'c4d8e2a17b93'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columnas = {c["name"] for c in inspector.get_columns("goal_contributions")}

    # 1. descripcion (opcional)
    if "descripcion" not in columnas:
        op.add_column(
            'goal_contributions',
            sa.Column('descripcion', sa.String(length=200), nullable=True),
        )

    # 2. fecha: se agrega nullable, se backfillea con DATE(created_at) y se fija NOT NULL.
    if "fecha" not in columnas:
        op.add_column(
            'goal_contributions',
            sa.Column('fecha', sa.Date(), nullable=True),
        )
        op.execute(
            "UPDATE goal_contributions SET fecha = DATE(created_at) WHERE fecha IS NULL"
        )
        op.alter_column(
            'goal_contributions', 'fecha',
            existing_type=sa.Date(), nullable=False,
        )
        op.create_index(
            op.f('ix_goal_contributions_fecha'), 'goal_contributions', ['fecha'], unique=False
        )


def downgrade() -> None:
    op.drop_index(op.f('ix_goal_contributions_fecha'), table_name='goal_contributions')
    op.drop_column('goal_contributions', 'fecha')
    op.drop_column('goal_contributions', 'descripcion')
