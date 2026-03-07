from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from app.core.config import settings
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
oauth2_scheme_optional = OAuth2PasswordBearer(tokenUrl="auth/login", auto_error=False)

async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        token_version = int(payload.get("ver", 0))
    except (JWTError, TypeError, ValueError):
        raise credentials_exception
        
    user = await User.get(user_id)
    if user is None:
        raise credentials_exception
    if token_version != int(getattr(user, "token_version", 0)):
        raise credentials_exception
    return user


async def get_optional_user(token: str | None = Depends(oauth2_scheme_optional)) -> User | None:
    if not token:
        return None
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str | None = payload.get("sub")
        if not user_id:
            return None
        token_version = int(payload.get("ver", 0))
        user = await User.get(user_id)
        if user is None:
            return None
        if token_version != int(getattr(user, "token_version", 0)):
            return None
        return user
    except (JWTError, TypeError, ValueError):
        return None
