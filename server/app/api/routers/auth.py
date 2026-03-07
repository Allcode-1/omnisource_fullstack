import hashlib
import secrets
import time
from datetime import datetime, timedelta, timezone
from threading import Lock
from urllib.parse import parse_qs, unquote, urlparse
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Request
from fastapi.security import OAuth2PasswordRequestForm
from app.models.user import User
from app.models.auth import PasswordReset
from app.schemas.user import UserCreate, UserRead, ForgotPassword, ResetPassword
from app.core.security import create_access_token, verify_password, get_password_hash
from app.core.config import settings
from app.core.email import send_reset_password_email
from app.core.logging import get_logger

router = APIRouter(prefix="/auth", tags=["auth"])
logger = get_logger(__name__)
_RATE_LIMIT_LOCK = Lock()
_RATE_LIMIT_BUCKETS: dict[str, tuple[int, float]] = {}


def _issue_access_token(user: User) -> str:
    token_version = int(getattr(user, "token_version", 0))
    try:
        return create_access_token(user.id, token_version=token_version)
    except TypeError:
        # Backward-compatibility for tests/mocks that monkeypatch one-arg signature.
        return create_access_token(user.id)


def _normalize_reset_token(raw_token: str) -> str:
    token = unquote((raw_token or "").strip()).strip('"').strip("'")
    if not token:
        return ""

    parsed = urlparse(token)
    if parsed.scheme and parsed.query:
        query_token = parse_qs(parsed.query).get("token", [""])[0].strip()
        if query_token:
            token = query_token

    # Copy-paste from emails often inserts line breaks or spaces.
    return token.replace(" ", "").replace("\n", "").replace("\r", "")


def _hash_reset_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


def _extract_client_ip(request: Request) -> str:
    forwarded = (request.headers.get("x-forwarded-for") or "").split(",")[0].strip()
    if forwarded:
        return forwarded
    return request.client.host if request.client else "unknown"


async def _consume_rate_limit(
    scope: str,
    identifier: str,
    max_attempts: int,
    window_seconds: int,
) -> bool:
    if max_attempts <= 0 or window_seconds <= 0:
        return True

    key = f"ratelimit:{scope}:{identifier}"
    now = time.monotonic()
    with _RATE_LIMIT_LOCK:
        current_count, reset_at = _RATE_LIMIT_BUCKETS.get(key, (0, now + window_seconds))
        if now >= reset_at:
            current_count = 0
            reset_at = now + window_seconds
        if current_count >= max_attempts:
            _RATE_LIMIT_BUCKETS[key] = (current_count, reset_at)
            return False
        _RATE_LIMIT_BUCKETS[key] = (current_count + 1, reset_at)
        return True


@router.post("/login")
async def login(request: Request, form_data: OAuth2PasswordRequestForm = Depends()):
    email = (form_data.username or "").strip().lower()
    client_ip = _extract_client_ip(request)
    can_proceed_email = await _consume_rate_limit(
        "login_email",
        email or "unknown",
        settings.AUTH_LOGIN_RATE_LIMIT_ATTEMPTS,
        settings.AUTH_LOGIN_RATE_LIMIT_WINDOW_SECONDS,
    )
    can_proceed_ip = await _consume_rate_limit(
        "login_ip",
        client_ip,
        settings.AUTH_LOGIN_RATE_LIMIT_ATTEMPTS,
        settings.AUTH_LOGIN_RATE_LIMIT_WINDOW_SECONDS,
    )
    if not (can_proceed_email and can_proceed_ip):
        raise HTTPException(status_code=429, detail="Too many login attempts. Try again later.")

    user = await User.find_one(User.email == email)
    if not user or not verify_password(form_data.password, user.hashed_password):
        logger.warning("Failed login attempt for email=%s", email)
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    
    return {
        "access_token": _issue_access_token(user),
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
        "access_token": _issue_access_token(new_user),
        "token_type": "bearer",
        "user": UserRead.model_validate(new_user)
    }

@router.post("/forgot-password")
async def forgot_password(
    data: ForgotPassword,
    background_tasks: BackgroundTasks,
    request: Request,
):
    email = data.email.strip().lower()
    client_ip = _extract_client_ip(request)
    can_proceed_email = await _consume_rate_limit(
        "reset_email",
        email,
        settings.AUTH_PASSWORD_RESET_RATE_LIMIT_ATTEMPTS,
        settings.AUTH_PASSWORD_RESET_RATE_LIMIT_WINDOW_SECONDS,
    )
    can_proceed_ip = await _consume_rate_limit(
        "reset_ip",
        client_ip,
        settings.AUTH_PASSWORD_RESET_RATE_LIMIT_ATTEMPTS,
        settings.AUTH_PASSWORD_RESET_RATE_LIMIT_WINDOW_SECONDS,
    )
    if not (can_proceed_email and can_proceed_ip):
        raise HTTPException(
            status_code=429,
            detail="Too many password reset attempts. Try again later.",
        )

    user = await User.find_one(User.email == email)
    if not user:
        # Do not leak user existence.
        logger.info("Password reset requested for non-existing email=%s", email)
        return {"message": "If the account exists, reset instructions were sent"}

    token = secrets.token_urlsafe(32)
    token_hash = _hash_reset_token(token)
    await PasswordReset.find(PasswordReset.email == email).delete()
    reset_entry = PasswordReset(
        email=email,
        token_hash=token_hash,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=15),
    )
    await reset_entry.insert()
    
    # send in background mode so user don't need to wait
    background_tasks.add_task(send_reset_password_email, email, token)
    
    logger.info("Password reset token issued for email=%s", email)
    return {"message": "If the account exists, reset instructions were sent"}

@router.post("/reset-password")
async def reset_password(data: ResetPassword):
    normalized_token = _normalize_reset_token(data.token)
    token_hash = _hash_reset_token(normalized_token)
    reset_entry = None
    if hasattr(PasswordReset, "token_hash"):
        reset_entry = await PasswordReset.find_one(
            PasswordReset.token_hash == token_hash,
        )
    # Legacy fallback for records created before token hashing migration.
    if reset_entry is None and hasattr(PasswordReset, "token"):
        reset_entry = await PasswordReset.find_one(
            PasswordReset.token == normalized_token,
        )

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
    user.token_version = int(getattr(user, "token_version", 0)) + 1
    await user.save()
    await reset_entry.delete()
    logger.info("Password reset completed for user id=%s", user.id)
    return {"message": "Password updated successfully"}
