import os
from datetime import datetime, timedelta, timezone

import jwt
from dotenv import load_dotenv
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pwdlib import PasswordHash
from sqlalchemy import select
from sqlalchemy.orm import Session

from database import get_db
from models import Operator, Passenger

load_dotenv()

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(
    os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30")
)

if not JWT_SECRET_KEY:
    raise RuntimeError("JWT_SECRET_KEY is missing from .env")

password_hasher = PasswordHash.recommended()
bearer_scheme = HTTPBearer()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return password_hasher.verify(plain_password, hashed_password)


def create_access_token(user_id: int, role: str) -> str:
    expires_at = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    payload = {
        "sub": str(user_id),
        "role": role,
        "exp": expires_at,
    }

    return jwt.encode(
        payload,
        JWT_SECRET_KEY,
        algorithm=JWT_ALGORITHM,
    )


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
):
    credentials_error = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired access token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET_KEY,
            algorithms=[JWT_ALGORITHM],
        )
        user_id = int(payload["sub"])
        role = payload["role"]

        if role not in {"passenger", "operator"}:
            raise credentials_error

    except (jwt.InvalidTokenError, KeyError, TypeError, ValueError):
        raise credentials_error

    if role == "passenger":
        user = db.scalar(
            select(Passenger).where(
                Passenger.id == user_id,
            )
        )
    else:
        user = db.scalar(
            select(Operator).where(
                Operator.id == user_id,
                Operator.is_active.is_(True),
            )
        )

    if user is None:
        raise credentials_error

    db.rollback()

    return {"id": user.id, "role": role, "user": user}


def require_passenger(current=Depends(get_current_user)):
    if current["role"] != "passenger":
        raise HTTPException(
            status_code=403,
            detail="Passenger access required",
        )
    return current


def require_operator(current=Depends(get_current_user)):
    if current["role"] != "operator":
        raise HTTPException(
            status_code=403,
            detail="Operator access required",
        )
    return current
