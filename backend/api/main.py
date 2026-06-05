from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.routes import auth, budgets, expenses, goals, alerts, simulator, smartscore
from core.config import settings
from db.session import engine
from db.models import Base

app = FastAPI(title=settings.PROJECT_NAME, version="1.0.0")

# Crear tablas solo si no estamos en modo Mock (si engine no es None)
if engine:
    Base.metadata.create_all(bind=engine)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(budgets.router, prefix="/api/budgets", tags=["Budgets"])
app.include_router(expenses.router, prefix="/api/expenses", tags=["Expenses"])
app.include_router(goals.router, prefix="/api/goals", tags=["Goals"])
app.include_router(alerts.router, prefix="/api/alerts", tags=["Alerts"])
app.include_router(simulator.router, prefix="/api/simulator", tags=["Simulator"])
app.include_router(smartscore.router, prefix="/api/smartscore", tags=["SmartScore"])

@app.get("/")
def read_root():
    return {"message": "API SmartBudget+ conectada y funcionando."}
