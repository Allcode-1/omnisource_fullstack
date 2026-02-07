from pydantic import BaseModel, EmailStr, Field, field_validator, ConfigDict
from pydantic_core import core_schema
from typing import List, Optional
import re

class UserBase(BaseModel):
    username: str
    email: EmailStr
    interests: List[str] = []

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)

    @field_validator('password')
    @classmethod
    def password_complexity(cls, v: str):
        if not re.search(r'[A-Z]', v):
            raise ValueError('Password must contain at least one uppercase letter')
        if not re.search(r'[a-z]', v):
            raise ValueError('Password must contain at least one lowercase letter')
        if not re.search(r'\d', v):
            raise ValueError('Password must contain at least one number')
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError('Password must contain at least one special character')
        return v

class UserUpdate(BaseModel):
    username: Optional[str] = None
    interests: Optional[List[str]] = None
    # avatar_url for future here

class PyObjectId(str):
    @classmethod
    def __get_pydantic_core_schema__(cls, _source_type, _handler):
        return core_schema.json_or_python_schema(
            json_schema=core_schema.str_schema(),
            python_schema=core_schema.union_schema([
                core_schema.is_instance_schema(cls),
                core_schema.chain_schema([
                    core_schema.is_instance_schema(object),
                    core_schema.no_info_plain_validator_function(str)
                ])
            ])
        )

class UserRead(UserBase):
    id: PyObjectId = Field(alias="_id") 
    
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True 
    )

class ForgotPassword(BaseModel):
    email: EmailStr

class ResetPassword(BaseModel):
    token: str
    new_password: str