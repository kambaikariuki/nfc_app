from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Numeric,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Passenger(Base):
    __tablename__ = "passengers"

    id: Mapped[int] = mapped_column(primary_key=True)
    full_name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(
        String(255), unique=True, index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    account: Mapped["Account"] = relationship(
        back_populates="passenger", uselist=False
    )
    cards: Mapped[list["NfcCard"]] = relationship(
        back_populates="passenger"
    )
    password_hash: Mapped[str] = mapped_column(String(255))


class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[int] = mapped_column(primary_key=True)
    passenger_id: Mapped[int] = mapped_column(
        ForeignKey("passengers.id"), unique=True
    )
    balance: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), default=Decimal("0.00")
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True
    )

    passenger: Mapped["Passenger"] = relationship(
        back_populates="account"
    )


class NfcCard(Base):
    __tablename__ = "nfc_cards"

    id: Mapped[int] = mapped_column(primary_key=True)
    uid: Mapped[str] = mapped_column(
        String(32), unique=True, index=True
    )
    passenger_id: Mapped[int] = mapped_column(
        ForeignKey("passengers.id")
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    passenger: Mapped["Passenger"] = relationship(
        back_populates="cards"
    )


class Operator(Base):
    __tablename__ = "operators"

    id: Mapped[int] = mapped_column(primary_key=True)
    full_name: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(
        String(255), unique=True, index=True
    )
    password_hash: Mapped[str] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True
    )

    wallet: Mapped["OperatorWallet"] = relationship(
        back_populates="operator", uselist=False
    )


class OperatorWallet(Base):
    __tablename__ = "operator_wallets"

    id: Mapped[int] = mapped_column(primary_key=True)
    operator_id: Mapped[int] = mapped_column(
        ForeignKey("operators.id"), unique=True
    )
    balance: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), default=Decimal("0.00")
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True
    )

    operator: Mapped["Operator"] = relationship(
        back_populates="wallet"
    )


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[int] = mapped_column(primary_key=True)
    request_id: Mapped[str] = mapped_column(
        String(100), unique=True, index=True
    )
    account_id: Mapped[int] = mapped_column(
        ForeignKey("accounts.id"), index=True
    )
    card_id: Mapped[int] = mapped_column(
        ForeignKey("nfc_cards.id")
    )
    operator_id: Mapped[int] = mapped_column(
        ForeignKey("operators.id"), index=True
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    status: Mapped[str] = mapped_column(
        String(20), default="completed"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class LedgerEntry(Base):
    __tablename__ = "ledger_entries"
    __table_args__ = (
        UniqueConstraint(
            "transaction_id",
            "entry_type",
            name="uq_ledger_transaction_entry_type",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    account_id: Mapped[int | None] = mapped_column(
        ForeignKey("accounts.id"), nullable=True
    )
    operator_wallet_id: Mapped[int | None] = mapped_column(
        ForeignKey("operator_wallets.id"), nullable=True
    )
    transaction_id: Mapped[int] = mapped_column(
        ForeignKey("transactions.id"), index=True
    )
    entry_type: Mapped[str] = mapped_column(String(10))
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    balance_after: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
