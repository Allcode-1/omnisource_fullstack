import uuid
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException, status, Depends, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm
from app.models.user import User
from app.models.auth import PasswordReset
from app.schemas.user import UserCreate, UserRead, ForgotPassword, ResetPassword
from app.core.security import create_access_token, verify_password, get_password_hash
from app.core.email import send_reset_password_email

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = await User.find_one(User.email == form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    return {
        "access_token": create_access_token(user.id), 
        "token_type": "bearer",
        "user": UserRead.model_validate(user)
    }

@router.post("/register", response_model=dict)
async def register(user_in: UserCreate):
    if await User.find_one(User.email == user_in.email):
        raise HTTPException(status_code=400, detail="Email already registered")
    
    new_user = User(
        username=user_in.username,
        email=user_in.email,
        hashed_password=get_password_hash(user_in.password),
        interests=user_in.interests,
        is_onboarding_complited=False
    )
    await new_user.insert()
    return {
        "access_token": create_access_token(new_user.id),
        "token_type": "bearer",
        "user": UserRead.model_validate(new_user)
    }

@router.post("/forgot-password")
async def forgot_password(data: ForgotPassword, background_tasks: BackgroundTasks):
    user = await User.find_one(User.email == data.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    token = str(uuid.uuid4())
    reset_entry = PasswordReset(
        email=data.email,
        token=token,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=15)
    )
    await reset_entry.insert()
    
    # send in background mode so user don't need to wait
    background_tasks.add_task(send_reset_password_email, data.email, token)
    
    return {"message": "Reset token sent to email"}

@router.post("/reset-password")
async def reset_password(data: ResetPassword):
    reset_entry = await PasswordReset.find_one(PasswordReset.token == data.token)
    
    now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
    
    if not reset_entry or reset_entry.expires_at < now_utc:
        raise HTTPException(status_code=400, detail="Invalid or expired token")
    
    user = await User.find_one(User.email == reset_entry.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.hashed_password = get_password_hash(data.new_password)
    await user.save()
    await reset_entry.delete()
    return {"message": "Password updated successfully"}