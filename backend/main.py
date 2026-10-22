
from decimal import Decimal
from uuid import UUID

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from database import get_db
from payments import pay_fare

from sqlalchemy import select
from models import Account, OperatorWallet, Transaction

app = FastAPI(title="NFC Fare Collection API")


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


@app.get("/passengers/{passenger_id}/balance")
def get_passenger_balance(passenger_id: int, db: Session = Depends(get_db)):
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
        "is_active": account.is_active,
    }


@app.get("/operators/{operator_id}/wallet")
def get_operator_wallet(operator_id: int, db: Session = Depends(get_db)):
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


@app.get("/passengers/{passenger_id}/transactions")
def get_passenger_transactions(passenger_id: int, db: Session = Depends(get_db)):
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

@app.get("/operators/{operator_id}/transactions")
def get_operator_transactions(operator_id: int, db: Session = Depends(get_db)):
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
