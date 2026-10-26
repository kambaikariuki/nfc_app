
from decimal import Decimal
from uuid import UUID

from fastapi import Depends, FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from database import get_db
from payments import pay_fare

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from models import Account, OperatorWallet, Transaction, Passenger, Operator
from schemas import LoginRequest, PassengerRegister

from auth import (
    create_access_token,
    password_hasher,
    require_operator,
    require_passenger,
    verify_password,
    get_current_user
)

app = FastAPI(title="NFC Fare Collection API")

# Authentication

@app.post("/auth/register", status_code=201)
def register_passenger(data: PassengerRegister, db: Session = Depends(get_db)):
    passenger = Passenger(
        full_name = data.full_name,
        email = str(data.email).lower,
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

@app.post("/auth/passenger/login")
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


@app.post("/auth/operator/login")
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


@app.get("/auth/me")
def get_my_profile(current=Depends(get_current_user)):
    user = current["user"]

    return {
        "id": user.id,
        "full_name": user.full_name,
        "email": user.email,
        "role": current["role"],
    }


class FarePaymentRequest(BaseModel):
    card_uid: str = Field(min_length=1, max_length=32)
    operator_id: int = Field(gt=0)
    amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    request_id: UUID


@app.get("/")
def read_root():
    return {"message": "NFC Fare Collection API is running"}


@app.post("/payments")
def create_payment(payment: FarePaymentRequest, db: Session = Depends(get_db)):
    return pay_fare(
        db=db,
        card_uid=payment.card_uid,
        operator_id=payment.operator_id,
        amount=payment.amount,
        request_id=str(payment.request_id),
    )


@app.get("/passengers/me/balance")
def get_passenger_balance(current=Depends(require_passenger), db: Session = Depends(get_db)):

    passenger_id = current["id"]

    account = db.scalar(
        select(Account).where(
            Account.passenger_id == passenger_id
        )
    )

    if account is None:
        raise HTTPException(404, "Passenger account not found")

    return {
        "passenger_id": passenger_id,
        "balance": str(account.balance),
    }


@app.get("/operators/me/wallet")
def get_operator_wallet(current=Depends(require_operator), db: Session = Depends(get_db)):
    operator_id = current["id"]
    wallet = db.scalar(
        select(OperatorWallet).where(
            OperatorWallet.operator_id == operator_id
        )
    )

    if wallet is None:
        raise HTTPException(404, "Operator wallet not found")

    return {
        "operator_id": operator_id,
        "balance": str(wallet.balance),
        "is_active": wallet.is_active,
    }


@app.get("/passengers/me/transactions")
def get_passenger_transactions(current=Depends(require_passenger), db: Session = Depends(get_db)):
    passenger_id = current["id"]

    account = db.scalar(
        select(Account).where(
            Account.passenger_id == passenger_id
        )
    )

    if account is None:
        raise HTTPException(404, "Passenger account not found")

    transactions = db.scalars(
        select(Transaction)
        .where(Transaction.account_id == account.id)
        .order_by(Transaction.created_at.desc())
        .limit(20)
    ).all()

    return [
        {
            "transaction_id": tx.id,
            "operator_id": tx.operator_id,
            "amount": str(tx.amount),
            "status": tx.status,
            "created_at": (
                tx.created_at.isoformat()
                if tx.created_at else None
            ),
        }
        for tx in transactions
    ]

@app.get("/operators/me/transactions")
def get_operator_transactions(current=Depends(require_operator), db: Session = Depends(get_db)):
    operator_id = current["id"]
    wallet = db.scalar(
        select(OperatorWallet).where(
            OperatorWallet.operator_id == operator_id
        )
    )

    if wallet is None:
        raise HTTPException(404, "Operator account not found")

    transactions = db.scalars(
        select(Transaction)
        .where(Transaction.account_id == wallet.id)
        .order_by(Transaction.created_at.desc())
        .limit(20)
    ).all()

    return [
        {
            "transaction_id": tx.id,
            "operator_id": tx.operator_id,
            "amount": str(tx.amount),
            "status": tx.status,
            "created_at": (
                tx.created_at.isoformat()
                if tx.created_at else None
            ),
        }
        for tx in transactions
    ]
