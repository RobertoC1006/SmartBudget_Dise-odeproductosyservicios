"""metas: columna categoria (logo/ilustración de la meta)

Revision ID: c4d8e2a17b93
Revises: b7e3a1f29c45
Create Date: 2026-06-13 09:00:00.000000

Agrega `goals.categoria` (texto) para el enfoque híbrido de selección de
categoría: la app sugiere una a partir del nombre y el usuario la puede
corregir. Solo afecta la ilustración del logo en Flutter, no la lógica
financiera. Idempotente: convive con `Base.metadata.create_all()`.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c4d8e2a17b93'
down_revision: Union[str, None] = 'b7e3a1f29c45'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    goal_columns = {c["name"] for c in inspector.get_columns("goals")}

    if "categoria" not in goal_columns:
        op.add_column(
            'goals',
            sa.Column('categoria', sa.String(length=20), nullable=False,
                      server_default='otros'),
        )


def downgrade() -> None:
    op.drop_column('goals', 'categoria')
