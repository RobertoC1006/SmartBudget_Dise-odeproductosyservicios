from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from db.session import SessionLocal
from core.security import decodificar_token
from core.exceptions import TokenInvalidoError
from db.models import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(token: str = Depends(oauth2_scheme), db = Depends(get_db)):
    try:
        payload = decodificar_token(token)
        user_id = int(payload["sub"])
    except TokenInvalidoError:
        raise HTTPException(status_code=401, detail="Token inválido o expirado")
        
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")
        
    return user
