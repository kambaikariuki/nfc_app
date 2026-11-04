from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from models import OperatorWallet, Transaction, Account, Passenger
from database import get_db
from auth import require_operator


router = APIRouter(
    prefix="/operators",
    tags=["Operators"]
)

@router.get("/wallet")
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

@router.get("/transactions")
def get_operator_transactions(
    current=Depends(require_operator),
    db: Session = Depends(get_db)
):
    operator_id = current["id"]

    wallet = db.scalar(
        select(OperatorWallet).where(
            OperatorWallet.operator_id == operator_id
        )
    )

    if wallet is None:
        raise HTTPException(404, "Operator account not found")

    transactions = db.execute(
        select(
            Transaction,
            Passenger.full_name
        )
        .join(
            Account,
            Transaction.account_id == Account.id
        )
        .join(
            Passenger,
            Account.passenger_id == Passenger.id
        )
        .where(Transaction.operator_id == operator_id)
        .order_by(Transaction.created_at.desc())
        .limit(20)
    ).all()

    return [
        {
            "transaction_id": tx.id,
            "passenger_name": passenger_name,
            "operator_id": tx.operator_id,
            "amount": str(tx.amount),
            "status": tx.status,
            "created_at": (
                tx.created_at.isoformat()
                if tx.created_at else None
            ),
        }
        for tx, passenger_name in transactions
    ]