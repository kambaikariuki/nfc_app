from decimal import Decimal
from uuid import uuid4

from sqlalchemy import text


def test_complete_payment_flow(
    client,
    db_connection,
    test_data,
    authenticated_operator,
):
    """
    Test the complete MatPay payment workflow:

    1. Deactivate the passenger's existing NFC card.
    2. Passenger registers a new NFC card.
    3. Operator processes a fare payment using that card.
    4. Verify passenger and operator balances.
    5. Verify transaction and ledger records.
    """

    passenger_id = test_data["passenger_id"]
    operator_id = test_data["operator_id"]

    new_card_uid = "04FF11223344"
    fare_amount = Decimal("50.00")
    request_id = str(uuid4())

    # --------------------------------------------------
    # 1. Deactivate the passenger's existing card
    # --------------------------------------------------

    db_connection.execute(
        text("""
            UPDATE nfc_cards
            SET is_active = FALSE
            WHERE passenger_id = :passenger_id
        """),
        {"passenger_id": passenger_id},
    )

    # --------------------------------------------------
    # 2. Passenger registers a new NFC card
    # --------------------------------------------------

    passenger_login = client.post(
        "/auth/passenger/login",
        json={
            "email": test_data["passenger_email"],
            "password": test_data["passenger_password"],
        },
    )

    assert passenger_login.status_code == 200, passenger_login.text

    passenger_token = passenger_login.json()["access_token"]

    passenger_headers = {
        "Authorization": f"Bearer {passenger_token}"
    }

    card_response = client.post(
        "/cards/register",
        json={"uid": new_card_uid},
        headers=passenger_headers,
    )

    assert card_response.status_code == 200, card_response.text
    assert card_response.json()["uid"] == new_card_uid

    # Verify that the card was persisted.
    card = db_connection.execute(
        text("""
            SELECT id, passenger_id, uid, is_active
            FROM nfc_cards
            WHERE uid = :uid
        """),
        {"uid": new_card_uid},
    ).mappings().one()

    assert card["passenger_id"] == passenger_id
    assert card["is_active"] is True

    # --------------------------------------------------
    # 3. Operator processes a fare payment
    # --------------------------------------------------

    payment_response = client.post(
        "/payments",
        json={
            "card_uid": new_card_uid,
            "amount": str(fare_amount),
            "request_id": request_id,
        },
        headers=authenticated_operator["headers"],
    )

    assert payment_response.status_code == 200, payment_response.text

    payment_data = payment_response.json()

    assert payment_data["status"] == "completed"
    assert payment_data["amount"] == "50.00"
    assert payment_data["passenger_balance"] == "450.00"
    assert payment_data["operator_balance"] == "50.00"

    transaction_id = payment_data["transaction_id"]

    # --------------------------------------------------
    # 4. Verify passenger account balance
    # --------------------------------------------------

    passenger_balance = db_connection.execute(
        text("""
            SELECT balance
            FROM accounts
            WHERE passenger_id = :passenger_id
        """),
        {"passenger_id": passenger_id},
    ).scalar_one()

    assert passenger_balance == Decimal("450.00")

    # --------------------------------------------------
    # 5. Verify operator wallet balance
    # --------------------------------------------------

    operator_balance = db_connection.execute(
        text("""
            SELECT balance
            FROM operator_wallets
            WHERE operator_id = :operator_id
        """),
        {"operator_id": operator_id},
    ).scalar_one()

    assert operator_balance == Decimal("50.00")

    # --------------------------------------------------
    # 6. Verify transaction record
    # --------------------------------------------------

    transaction = db_connection.execute(
        text("""
            SELECT id, request_id, account_id, card_id,
                   operator_id, amount, status
            FROM transactions
            WHERE id = :transaction_id
        """),
        {"transaction_id": transaction_id},
    ).mappings().one()

    assert transaction["request_id"] == request_id
    assert transaction["card_id"] == card["id"]
    assert transaction["operator_id"] == operator_id
    assert transaction["amount"] == fare_amount
    assert transaction["status"] == "completed"

    # --------------------------------------------------
    # 7. Verify both ledger entries
    # --------------------------------------------------

    ledger_entries = db_connection.execute(
        text("""
            SELECT account_id, operator_wallet_id,
                   entry_type, amount, balance_after
            FROM ledger_entries
            WHERE transaction_id = :transaction_id
        """),
        {"transaction_id": transaction_id},
    ).mappings().all()

    assert len(ledger_entries) == 2

    debit_entry = next(
        entry for entry in ledger_entries
        if entry["entry_type"] == "debit"
    )

    credit_entry = next(
        entry for entry in ledger_entries
        if entry["entry_type"] == "credit"
    )

    assert debit_entry["account_id"] == transaction["account_id"]
    assert debit_entry["amount"] == Decimal("-50.00")
    assert debit_entry["balance_after"] == Decimal("450.00")

    assert credit_entry["operator_wallet_id"] is not None
    assert credit_entry["amount"] == Decimal("50.00")
    assert credit_entry["balance_after"] == Decimal("50.00")

    # --------------------------------------------------
    # 8. Verify that the payment was recorded only once
    # --------------------------------------------------

    transaction_count = db_connection.execute(
        text("""
            SELECT COUNT(*)
            FROM transactions
            WHERE request_id = :request_id
        """),
        {"request_id": request_id},
    ).scalar_one()

    assert transaction_count == 1
