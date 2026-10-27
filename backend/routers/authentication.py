from fastapi import Depends, HTTPException, APIRouter
from decimal import Decimal

from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from schemas import PassengerRegister, LoginRequest
from models import Passenger, Account, Operator
from database import get_db
from auth import password_hasher, verify_password, create_access_token, get_current_user

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

@router.post("/register", status_code=201)
def register_passenger(data: PassengerRegister, db: Session = Depends(get_db)):
    passenger = Passenger(
        full_name = data.full_name,
        email = str(data.email).lower(),
        password_hash = password_hasher.hash(data.password)
    )

    try:
        with db.begin():
            db.add(passenger)
            db.flush()

            db.add(
                Account(
                    passenger_id = passenger.id,
                    balance = Decimal("0.00"),
                    is_active = True,
                )
            )
    except IntegrityError:
        raise HTTPException(
            status_code=409,
            detail="An account with this email already exists",
        )

    return {"message": "Passenger registered successfully."}

@router.post("/passenger/login")
def passenger_login(data: LoginRequest, db: Session = Depends(get_db)):
    passenger = db.scalar(select(Passenger).where(
        Passenger.email == str(data.email).lower()
    )
    )

    if (passenger is None or not verify_password(data.password, passenger.password_hash)):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = create_access_token(passenger.id, "passenger")

    return {
        "access_token": token,
        "token_type": "bearer"
    }


@router.post("/operator/login")
def operator_login(data: LoginRequest, db: Session = Depends(get_db)):
    operator = db.scalar(select(Operator).where(
        Operator.email == str(data.email).lower()
    ))

    if (operator is None
        or not operator.is_active
        or not verify_password(data.password, operator.password_hash)):

        raise HTTPException(
            status_code=401,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = create_access_token(operator.id, "operator")

    return {
        "access_token": token,
        "token_type": "bearer", 
    }


@router.get("/me")
def get_my_profile(current=Depends(get_current_user)):
    user = current["user"]

    return {
        "id": user.id,
        "full_name": user.full_name,
        "email": user.email,
        "role": current["role"],
    }
