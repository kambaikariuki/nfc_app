from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from auth import require_passenger
from database import get_db
from models import Account, Transaction, NfcCard
from schemas import LinkCardRequest

router = APIRouter(
    prefix="/passengers",
    tags=["Passengers"]
)

@router.get("/balance")
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



@router.get("/transactions")
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

@router.post("/cards")
def link_nfc_card(card_data: LinkCardRequest, current: dict = Depends(require_passenger), db: Session = Depends(get_db)):
    uid = card_data.uid.strip().upper()

    existing_card = db.scalar(
        select(NfcCard).where(NfcCard.uid == uid)
    )

    if existing_card:
        raise HTTPException(409, "This NFC card is already registered")

    card = NfcCard(
        uid=uid,
        passenger_id=current["id"],
        is_active=True
    )

    try:
        db.add(card)
        db.commit()
        db.refresh(card)
    except Exception:
        db.rollback()
        raise HTTPException(409, "Could not link card.")

    return {
        "message": "NFC card linked successfully",
        "uid": card.uid
    }