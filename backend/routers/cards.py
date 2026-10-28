from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session
from models import NfcCard
from schemas import LinkCardRequest
from database import get_db
from auth import require_passenger


router = APIRouter(
    prefix="/cards",
    tags=["Cards"]
)

@router.get("/me")
def get_card(current: dict = Depends(require_passenger), db: Session = Depends(get_db)):
    cards = db.scalars(select(NfcCard).where(
            NfcCard.passenger_id == current["id"]
        )).all()

    if cards is None:
        raise HTTPException(404, "Card account not found")

    return [
        {
            "card_uid": card.uid,
            "is_active": card.is_active
        }
        for card in cards
    ]
    
@router.post("/register")
def link_nfc_card(card_data: LinkCardRequest, current: dict = Depends(require_passenger), db: Session = Depends(get_db)):
    uid = card_data.uid.strip().upper()

    existing_card = db.scalar(
        select(NfcCard).where(
            NfcCard.uid == uid            
        )
    )
    if existing_card:
        raise HTTPException(409, "This NFC card is already registered and in use.")

    duplicate_card = db.scalar(
        select(NfcCard).where(
            NfcCard.passenger_id == current["id"],
            NfcCard.is_active.is_(True)            
        ))

    if duplicate_card:
        raise HTTPException(409, "You already have an active card. Deactivate it before registering a replacement.")

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

@router.delete("/delete")
def delete_card(current: dict = Depends(require_passenger), db: Session = Depends(get_db)):
    card = db.scalar(select(NfcCard).where(
        NfcCard.passenger_id == current["id"]
    ))

    

    if not card:
        raise HTTPException(404, "Card not found.")

    try:
        card.is_active = False
        db.commit()

        return {
            "message": "Card deactivated successfully",
            "card_uid": card.uid,
            "is_active": card.is_active
        }

    except Exception:
        db.rollback()
        raise HTTPException(500, "Failed to deactivate card.")
    