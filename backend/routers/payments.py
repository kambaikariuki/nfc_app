from fastapi import APIRouter
from sqlalchemy.orm import Session
from schemas import FarePaymentRequest
from fastapi import Depends
from database import get_db
from auth import require_operator
from payments import pay_fare

router = APIRouter(
    prefix="/payments",
    tags=["Payments"]
)

@router.post("")
def create_payment(payment: FarePaymentRequest, current=Depends(require_operator), db: Session = Depends(get_db)):
    return pay_fare(
        db=db,
        card_uid=payment.card_uid,
        operator_id=current["id"],
        amount=payment.amount,
        request_id=str(payment.request_id),
    )
