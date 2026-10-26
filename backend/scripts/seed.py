from decimal import Decimal
from pwdlib import PasswordHash
from sqlalchemy import select

from database import SessionLocal
from models import (
    Account,
    NfcCard,
    Operator,
    OperatorWallet,
    Passenger,
)

password_hash = PasswordHash.recommended()

# Development-only test credentials
PASSENGER_EMAIL = "passenger@test.com"
PASSENGER_PASSWORD = "Passenger123!"

OPERATOR_EMAIL = "operator@test.com"
OPERATOR_PASSWORD = "Operator123!"

CARD_UID = "04A1B2C3D4"


def seed_database():
    with SessionLocal() as db:
        try:
            # Create or reuse passenger
            passenger = db.scalar(
                select(Passenger).where(
                    Passenger.email == PASSENGER_EMAIL
                )
            )

            if passenger is None:
                passenger = Passenger(
                    full_name="Test Passenger",
                    email=PASSENGER_EMAIL,
                    password_hash=password_hash.hash(
                        PASSENGER_PASSWORD
                    ),
                )
                db.add(passenger)
                db.flush()
            else:
                # Ensure the existing test account has a valid hash.
                passenger.password_hash = password_hash.hash(
                    PASSENGER_PASSWORD
                )

            # Create or reuse passenger account
            account = db.scalar(
                select(Account).where(
                    Account.passenger_id == passenger.id
                )
            )

            if account is None:
                db.add(
                    Account(
                        passenger_id=passenger.id,
                        balance=Decimal("500.00"),
                        is_active=True,
                    )
                )

            # Create or reuse NFC card
            card = db.scalar(
                select(NfcCard).where(
                    NfcCard.uid == CARD_UID
                )
            )

            if card is None:
                db.add(
                    NfcCard(
                        uid=CARD_UID,
                        passenger_id=passenger.id,
                        is_active=True,
                    )
                )
            elif card.passenger_id != passenger.id:
                raise ValueError(
                    "The test card is already linked to another passenger."
                )

            # Create or reuse operator
            operator = db.scalar(
                select(Operator).where(
                    Operator.email == OPERATOR_EMAIL
                )
            )

            if operator is None:
                operator = Operator(
                    full_name="Test Operator",
                    email=OPERATOR_EMAIL,
                    password_hash=password_hash.hash(
                        OPERATOR_PASSWORD
                    ),
                    is_active=True,
                )
                db.add(operator)
                db.flush()
            else:
                operator.password_hash = password_hash.hash(
                    OPERATOR_PASSWORD
                )

            # Create or reuse operator wallet
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

            print("Test data seeded successfully.")
            print(f"Passenger email: {PASSENGER_EMAIL}")
            print(f"Passenger password: {PASSENGER_PASSWORD}")
            print(f"Operator email: {OPERATOR_EMAIL}")
            print(f"Operator password: {OPERATOR_PASSWORD}")
            print(f"Operator ID: {operator.id}")
            print(f"Test NFC card UID: {CARD_UID}")

        except Exception:
            db.rollback()
            raise


if __name__ == "__main__":
    seed_database()
