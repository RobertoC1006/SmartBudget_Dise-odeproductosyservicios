from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordRequestForm
from api.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, UserResponse
from api.dependencies import get_db, get_current_user
from core.security import obtener_password_hash, verificar_password, crear_token_acceso
from db.models import User

router = APIRouter()

@router.post("/register", response_model=UserResponse, status_code=201)
def register(req: RegisterRequest, db=Depends(get_db)):
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=400, detail="El email ya está registrado")
    
    user = User(
        nombre=req.nombre,
        email=req.email,
        hashed_password=obtener_password_hash(req.password)
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

# Para soportar el "Authorize" de Swagger, usamos OAuth2PasswordRequestForm
@router.post("/login", response_model=TokenResponse)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db=Depends(get_db)):
    # Swagger envía el email en el campo "username"
    user = db.query(User).filter(User.email == form_data.username).first()
    
    if not user or not verificar_password(form_data.password, user.hashed_password):
        raise HTTPException(401, "Credenciales inválidas")
        
    token = crear_token_acceso({"sub": str(user.id), "email": user.email})
    return {"access_token": token, "token_type": "bearer"}

@router.get("/me", response_model=UserResponse)
def get_me(user=Depends(get_current_user)):
    return user
