from pydantic import BaseModel, EmailStr, Field
from uuid import UUID
from decimal import Decimal


class PassengerRegister(BaseModel):
    full_name: str = Field(min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

class OperatorRegister(BaseModel):
    full_name: str = Field(min_length=2, max_length=150)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=128)

class FarePaymentRequest(BaseModel):
    card_uid: str = Field(min_length=1, max_length=32)
    amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    request_id: UUID


class LinkCardRequest(BaseModel):
    uid: str = Field(min_length=1, max_length=32)