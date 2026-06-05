from pydantic import BaseModel, EmailStr, Field, ConfigDict
from datetime import datetime

class RegisterRequest(BaseModel):
    nombre: str
    email: EmailStr
    password: str = Field(min_length=8)

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserResponse(BaseModel):
    id: int
    nombre: str
    email: str
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)
