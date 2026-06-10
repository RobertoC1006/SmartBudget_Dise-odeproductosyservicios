from pydantic import BaseModel, EmailStr, Field, ConfigDict
from datetime import datetime
from typing import Optional
from core.enums import OcupacionUsuario

class RegisterRequest(BaseModel):
    nombre: str
    email: EmailStr
    password: str = Field(min_length=8)
    ocupacion: Optional[OcupacionUsuario] = None

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserUpdateRequest(BaseModel):
    ocupacion: Optional[OcupacionUsuario] = None

class UserResponse(BaseModel):
    id: int
    nombre: str
    email: str
    ocupacion: Optional[OcupacionUsuario] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
