import datetime
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from core.config import settings
from db.models import Base


# ─── MODO DE OPERACIÓN ──────────────────────────────────────────────────────
# Si en el .env pones USE_MOCK_DB=True, se usará el Mock de Fabián.
# Si no está o es False, se usará la conexión real a MySQL.
USE_MOCK = os.getenv("USE_MOCK_DB", "True").lower() == "true"

# ─── MOCK DATABASE (Memoria temporal) ───────────────────────────────────────
MOCK_STORAGE = {
    "users": [],
    "budgets": [],
    "expenses": [],
    "goals": [],
    "alerts": []
}

if USE_MOCK:
    class MockQuery:
        def __init__(self, model_class, db_session):
            self.model_class = model_class
            self.db_session = db_session
            self.filter_kwargs = {}

        def filter(self, *args, **kwargs):
            self.filter_kwargs.update(kwargs)
            for arg in args:
                try:
                    # En SQLAlchemy, las expresiones de comparación (==) tienen left y right
                    if hasattr(arg, "left") and hasattr(arg, "right"):
                        key = getattr(arg.left, "key", None)
                        right = arg.right
                        # Si es un objeto de parámetro de enlace, extraemos su valor
                        value = getattr(right, "value", right)
                        if key is not None:
                            self.filter_kwargs[key] = value
                except Exception:
                    pass
            return self

        def first(self):
            table = self.model_class.__tablename__
            items = MOCK_STORAGE.get(table, [])
            
            if not self.filter_kwargs and not items:
                # Si no hay nada y es el primer inicio, podemos devolver un default
                from db.models import User
                if self.model_class == User:
                    return User(id=1, nombre="Roberto", email="Roberto", hashed_password="mock")
                return None
                
            # Si hay filtros, buscamos (muy básico)
            for item in items:
                match = True
                for k, v in self.filter_kwargs.items():
                    if getattr(item, k, None) != v:
                        match = False
                        break
                if match: return item
            
            # Si no hay filtros, devolvemos el primero
            return items[0] if items else None

        def all(self):
            return MOCK_STORAGE.get(self.model_class.__tablename__, [])
            
        def count(self):
            return len(self.all())

    class MockSessionLocal:
        def __init__(self): pass
        def query(self, model_class): return MockQuery(model_class, self)
        
        def add(self, obj):
            table = obj.__tablename__
            if table not in MOCK_STORAGE: MOCK_STORAGE[table] = []
            
            # Aplicar valores por defecto definidos en el mapeo de SQLAlchemy
            try:
                for col in obj.__mapper__.columns:
                    val = getattr(obj, col.key, None)
                    if val is None and col.default is not None:
                        if hasattr(col.default, 'arg'):
                            arg = col.default.arg
                            if callable(arg):
                                try:
                                    setattr(obj, col.key, arg(None))
                                except Exception:
                                    setattr(obj, col.key, arg())
                            else:
                                setattr(obj, col.key, arg)
            except Exception:
                pass

            # Asignar ID si no tiene
            if not getattr(obj, "id", None):
                obj.id = len(MOCK_STORAGE[table]) + 1
            
            MOCK_STORAGE[table].append(obj)

        def commit(self): pass
        def refresh(self, obj):
            from datetime import datetime
            if hasattr(obj, 'created_at') and not getattr(obj, 'created_at'):
                obj.created_at = datetime.now()
        def close(self): pass

    SessionLocal = MockSessionLocal
    engine = None
    print("⚠️  AVISO: Usando BASE DE DATOS MOCK con memoria temporal")
else:
    # ─── CONEXIÓN REAL (Para Roberto y Producción) ───
    # Usamos pool_pre_ping=True para que SQLAlchemy verifique si la conexión 
    # sigue viva antes de usarla (evita errores tras periodos de inactividad).
    engine = create_engine(
        settings.DATABASE_URL, 
        pool_pre_ping=True,
        pool_recycle=3600
    )
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    print("✅ CONEXIÓN REAL: MySQL en Docker está activa")

def get_db_session():
    """
    Función de utilidad para obtener una sesión.
    En FastAPI se usa via Dependencia (Depends).
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
