from decimal import Decimal

from sqlalchemy import select

from database import SessionLocal
from models import (
    Account,
    NfcCard,
    Operator,
    OperatorWallet,
    Passenger,
)

with SessionLocal() as db:
    # Reuse the test passenger if this script has already run.
    passenger = db.scalar(
        select(Passenger).where(
            Passenger.email == "passenger@test.com"
        )
    )

    if passenger is None:
        passenger = Passenger(
            full_name="Test Passenger",
            email="passenger@test.com",
        )
        db.add(passenger)
        db.flush()

        db.add(
            Account(
                passenger_id=passenger.id,
                balance=Decimal("500.00"),
                is_active=True,
            )
        )

    db.flush()

    card = db.scalar(
        select(NfcCard).where(NfcCard.uid == "04A1B2C3D4")
    )

    if card is None:
        db.add(
            NfcCard(
                uid="04A1B2C3D4",
                passenger_id=passenger.id,
                is_active=True,
            )
        )

    operator = db.scalar(
        select(Operator).where(
            Operator.email == "operator@test.com"
        )
    )

    if operator is None:
        operator = Operator(
            full_name="Test Operator",
            email="operator@test.com",
            password_hash="development-only-not-a-real-password-hash",
            is_active=True,
        )
        db.add(operator)
        db.flush()

    wallet = db.scalar(
        select(OperatorWallet).where(
            OperatorWallet.operator_id == operator.id
        )
    )

    if wallet is None:
        db.add(
            OperatorWallet(
                operator_id=operator.id,
                balance=Decimal("0.00"),
                is_active=True,
            )
        )

    db.commit()

    print("Test data ready!")
    print(f"Passenger email: {passenger.email}")
    print(f"Operator ID: {operator.id}")
    print("Card UID: 04A1B2C3D4")
