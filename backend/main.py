
from decimal import Decimal
from uuid import UUID

from fastapi import Depends, FastAPI
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from database import get_db
from payments import pay_fare

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
def create_payment(
    payment: FarePaymentRequest,
    db: Session = Depends(get_db),
):
    return pay_fare(
        db=db,
        card_uid=payment.card_uid,
        operator_id=payment.operator_id,
        amount=payment.amount,
        request_id=str(payment.request_id),
    )
