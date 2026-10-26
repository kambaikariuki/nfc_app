from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from models import (
    Account,
    LedgerEntry,
    NfcCard,
    Operator,
    OperatorWallet,
    Transaction,
)


def pay_fare(
    db: Session,
    card_uid: str,
    operator_id: int,
    amount: Decimal,
    request_id: str,
):
    if not amount.is_finite() or amount <= Decimal("0.00"):
        raise HTTPException(400, "Fare must be greater than zero")

    if amount != amount.quantize(Decimal("0.01")):
        raise HTTPException(400, "Fare cannot have more than two decimals")

    if not request_id.strip():
        raise HTTPException(400, "Request ID is required")

    try:
        
        # Prevent the same payment request from being processed twice.
        existing = db.scalar(
            select(Transaction).where(
                Transaction.request_id == request_id
            )
        )
        if existing:
            raise HTTPException(
                409, "This payment request has already been processed"
            )

        card = db.scalar(
            select(NfcCard)
            .where(
                NfcCard.uid == card_uid,
                NfcCard.is_active.is_(True),
            )
            .with_for_update()
        )
        if card is None:
            raise HTTPException(404, "Active NFC card not found")

        account = db.scalar(
            select(Account)
            .where(Account.passenger_id == card.passenger_id)
            .with_for_update()
        )
        if account is None or not account.is_active:
            raise HTTPException(400, "Passenger account is unavailable")

        operator = db.scalar(
            select(Operator).where(
                Operator.id == operator_id,
                Operator.is_active.is_(True),
            )
        )
        if operator is None:
            raise HTTPException(404, "Active operator not found")

        wallet = db.scalar(
            select(OperatorWallet)
            .where(OperatorWallet.operator_id == operator_id)
            .with_for_update()
        )
        if wallet is None or not wallet.is_active:
            raise HTTPException(400, "Operator wallet is unavailable")

        if account.balance < amount:
            raise HTTPException(400, "Insufficient passenger balance")

        # Transfer the full fare. No platform commission.
        account.balance -= amount
        wallet.balance += amount

        transaction = Transaction(
            request_id=request_id,
            account_id=account.id,
            card_id=card.id,
            operator_id=operator.id,
            amount=amount,
            status="completed",
        )
        db.add(transaction)
        db.flush()

        db.add_all([
            LedgerEntry(
                account_id=account.id,
                transaction_id=transaction.id,
                entry_type="debit",
                amount=-amount,
                balance_after=account.balance,
            ),
            LedgerEntry(
                operator_wallet_id=wallet.id,
                transaction_id=transaction.id,
                entry_type="credit",
                amount=amount,
                balance_after=wallet.balance,
            ),
        ])

        db.commit()

        result = {
            "transaction_id": transaction.id,
            "status": "completed",
            "amount": str(amount),
            "passenger_balance": str(account.balance),
            "operator_balance": str(wallet.balance),
        }

        return result

    except Exception:
        db.rollback()
        raise
