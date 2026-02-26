import uuid
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException, status, Depends, BackgroundTasks
from fastapi.security import OAuth2PasswordRequestForm
from app.models.user import User
from app.models.auth import PasswordReset
from app.schemas.user import UserCreate, UserRead, ForgotPassword, ResetPassword
from app.core.security import create_access_token, verify_password, get_password_hash
from app.core.email import send_reset_password_email
from app.core.logging import get_logger

router = APIRouter(prefix="/auth", tags=["auth"])
logger = get_logger(__name__)


@router.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = await User.find_one(User.email == form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        logger.warning("Failed login attempt for email=%s", form_data.username)
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
        is_onboarding_completed=False
    )
    await new_user.insert()
    logger.info("Registered new user id=%s email=%s", new_user.id, new_user.email)
    return {
        "access_token": create_access_token(new_user.id),
        "token_type": "bearer",
        "user": UserRead.model_validate(new_user)
    }

@router.post("/forgot-password")
async def forgot_password(data: ForgotPassword, background_tasks: BackgroundTasks):
    user = await User.find_one(User.email == data.email)
    if not user:
        # Do not leak user existence.
        logger.info("Password reset requested for non-existing email=%s", data.email)
        return {"message": "If the account exists, reset instructions were sent"}
    
    token = str(uuid.uuid4())
    await PasswordReset.find(PasswordReset.email == data.email).delete()
    reset_entry = PasswordReset(
        email=data.email,
        token=token,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=15)
    )
    await reset_entry.insert()
    
    # send in background mode so user don't need to wait
    background_tasks.add_task(send_reset_password_email, data.email, token)
    
    logger.info("Password reset token issued for email=%s", data.email)
    return {"message": "If the account exists, reset instructions were sent"}

@router.post("/reset-password")
async def reset_password(data: ResetPassword):
    reset_entry = await PasswordReset.find_one(PasswordReset.token == data.token)

    now_utc = datetime.now(timezone.utc)

    if not reset_entry:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

    expires_at = reset_entry.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)

    if expires_at < now_utc:
        raise HTTPException(status_code=400, detail="Invalid or expired token")
    
    user = await User.find_one(User.email == reset_entry.email)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.hashed_password = get_password_hash(data.new_password)
    await user.save()
    await reset_entry.delete()
    logger.info("Password reset completed for user id=%s", user.id)
    return {"message": "Password updated successfully"}
