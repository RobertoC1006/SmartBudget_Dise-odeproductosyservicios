"""
tests/test_goals_api.py — Tests de integración HTTP de los endpoints de metas (Fase 0)

Ejercita el camino completo por la API real (FastAPI TestClient) con la BD y el
usuario sobreescritos: crear con fecha+recordatorio, aportar con delta de
SmartScore, historial de aportes, edición y borrado.
"""

from datetime import date

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient

from api.main import app
from api.dependencies import get_db, get_current_user
from db.models import Base, User
from core.budgets import crear_presupuesto_mes

engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(bind=engine, expire_on_commit=False)


@pytest.fixture
def client():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    user = User(id=1, nombre="Test", email="api@test.com", hashed_password="...")
    db.add(user)
    db.commit()
    # Presupuesto del mes actual para que el aporte y el SmartScore funcionen
    hoy = date.today()
    crear_presupuesto_mes(db, user_id=1, monto_base=2000, mes=hoy.month, anio=hoy.year)
    db.close()

    def override_get_db():
        session = TestingSessionLocal()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user] = lambda: user

    yield TestClient(app)

    app.dependency_overrides.clear()
    Base.metadata.drop_all(bind=engine)


def test_flujo_completo_metas_api(client):
    # 1. Crear meta con fecha objetivo y recordatorio
    resp = client.post("/api/goals/", json={
        "nombre": "Viaje a Cusco",
        "monto_objetivo": 1000,
        "fecha_limite": "2026-12-05",
        "categoria": "viaje",
        "recordatorio": True,
    })
    assert resp.status_code == 200, resp.text
    meta = resp.json()
    goal_id = meta["id"]
    assert meta["recordatorio"] is True
    assert meta["fecha_limite"] == "2026-12-05"
    assert meta["categoria"] == "viaje"

    # 2. Aportar (monto en el body) -> devuelve delta real de SmartScore
    resp = client.post(f"/api/goals/{goal_id}/contribute", json={"monto": 500})
    assert resp.status_code == 200, resp.text
    result = resp.json()
    assert result["saldo_acumulado"] == 500
    assert "score_delta" in result
    assert result["score_nuevo"] == result["score_anterior"] + result["score_delta"]
    # Aportar sube el progreso de metas -> el score no baja
    assert result["score_delta"] >= 0

    # 3. Historial de aportes
    resp = client.get(f"/api/goals/{goal_id}/contributions")
    assert resp.status_code == 200, resp.text
    aportes = resp.json()
    assert len(aportes) == 1
    assert aportes[0]["monto"] == 500

    # 4. Editar la meta
    resp = client.put(f"/api/goals/{goal_id}", json={
        "nombre": "Viaje a Cusco 2026",
        "monto_objetivo": 1500,
    })
    assert resp.status_code == 200, resp.text
    assert resp.json()["nombre"] == "Viaje a Cusco 2026"
    assert resp.json()["monto_objetivo"] == 1500

    # 5. Eliminar la meta
    resp = client.delete(f"/api/goals/{goal_id}")
    assert resp.status_code == 204, resp.text

    # 6. La meta ya no aparece
    resp = client.get("/api/goals/")
    assert resp.status_code == 200
    assert all(g["id"] != goal_id for g in resp.json())
