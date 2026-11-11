
from decimal import Decimal
from uuid import uuid4

from sqlalchemy import text


def make_payment(client, headers, amount="50.00", request_id=None):
    return client.post(
        "/payments",
        headers=headers,
        json={
            "card_uid": "04A1B2C3D4",
            "amount": amount,
            "request_id": request_id or str(uuid4()),
        },
    )


def test_successful_payment_creates_one_transaction(
    client,
    authenticated_operator,
    db_connection,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
    )

    assert response.status_code == 200, response.text

    count = db_connection.execute(
        text("SELECT COUNT(*) FROM transactions")
    ).scalar_one()

    assert count == 1


def test_transaction_has_correct_details(
    client,
    authenticated_operator,
    db_connection,
):
    data = authenticated_operator["data"]

    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="50.00",
    )

    assert response.status_code == 200, response.text

    transaction_id = response.json()["transaction_id"]

    transaction = db_connection.execute(
        text("""
            SELECT
                account_id,
                card_id,
                operator_id,
                amount,
                status
            FROM transactions
            WHERE id = :transaction_id
        """),
        {"transaction_id": transaction_id},
    ).mappings().one()

    assert transaction["account_id"] == data["account_id"]
    assert transaction["card_id"] == data["card_id"]
    assert transaction["operator_id"] == data["operator_id"]
    assert transaction["amount"] == Decimal("50.00")
    assert transaction["status"] == "completed"


def test_transaction_creates_two_ledger_entries(
    client,
    authenticated_operator,
    db_connection,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
    )

    assert response.status_code == 200, response.text

    transaction_id = response.json()["transaction_id"]

    count = db_connection.execute(
        text("""
            SELECT COUNT(*)
            FROM ledger_entries
            WHERE transaction_id = :transaction_id
        """),
        {"transaction_id": transaction_id},
    ).scalar_one()

    assert count == 2


def test_passenger_debit_ledger_entry(
    client,
    authenticated_operator,
    db_connection,
    test_data,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="50.00",
    )

    assert response.status_code == 200, response.text

    transaction_id = response.json()["transaction_id"]

    debit = db_connection.execute(
        text("""
            SELECT
                account_id,
                operator_wallet_id,
                amount,
                balance_after
            FROM ledger_entries
            WHERE transaction_id = :transaction_id
              AND entry_type = 'debit'
        """),
        {"transaction_id": transaction_id},
    ).mappings().one()

    assert debit["account_id"] == test_data["account_id"]
    assert debit["operator_wallet_id"] is None
    assert debit["amount"] == Decimal("-50.00")
    assert debit["balance_after"] == Decimal("450.00")


def test_operator_credit_ledger_entry(
    client,
    authenticated_operator,
    db_connection,
    test_data,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="50.00",
    )

    assert response.status_code == 200, response.text

    transaction_id = response.json()["transaction_id"]

    credit = db_connection.execute(
        text("""
            SELECT
                account_id,
                operator_wallet_id,
                amount,
                balance_after
            FROM ledger_entries
            WHERE transaction_id = :transaction_id
              AND entry_type = 'credit'
        """),
        {"transaction_id": transaction_id},
    ).mappings().one()

    assert credit["account_id"] is None
    assert credit["operator_wallet_id"] == test_data["wallet_id"]
    assert credit["amount"] == Decimal("50.00")
    assert credit["balance_after"] == Decimal("50.00")


def test_ledger_entries_record_correct_balances(
    client,
    authenticated_operator,
    db_connection,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="100.00",
    )

    assert response.status_code == 200, response.text

    transaction_id = response.json()["transaction_id"]

    entries = db_connection.execute(
        text("""
            SELECT entry_type, amount, balance_after
            FROM ledger_entries
            WHERE transaction_id = :transaction_id
        """),
        {"transaction_id": transaction_id},
    ).mappings().all()

    entries_by_type = {
        entry["entry_type"]: entry
        for entry in entries
    }

    assert entries_by_type["debit"]["amount"] == Decimal("-100.00")
    assert entries_by_type["debit"]["balance_after"] == Decimal("400.00")

    assert entries_by_type["credit"]["amount"] == Decimal("100.00")
    assert entries_by_type["credit"]["balance_after"] == Decimal("100.00")


def test_failed_payment_creates_no_transaction_or_ledger_entries(
    client,
    authenticated_operator,
    db_connection,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="600.00",
    )

    assert response.status_code == 400

    transaction_count = db_connection.execute(
        text("SELECT COUNT(*) FROM transactions")
    ).scalar_one()

    ledger_count = db_connection.execute(
        text("SELECT COUNT(*) FROM ledger_entries")
    ).scalar_one()

    assert transaction_count == 0
    assert ledger_count == 0


def test_duplicate_request_creates_no_duplicate_records(
    client,
    authenticated_operator,
    db_connection,
):
    headers = authenticated_operator["headers"]
    request_id = str(uuid4())

    first_response = make_payment(
        client,
        headers,
        amount="50.00",
        request_id=request_id,
    )

    assert first_response.status_code == 200, first_response.text

    second_response = make_payment(
        client,
        headers,
        amount="50.00",
        request_id=request_id,
    )

    assert second_response.status_code == 409

    transaction_count = db_connection.execute(
        text("""
            SELECT COUNT(*)
            FROM transactions
            WHERE request_id = :request_id
        """),
        {"request_id": request_id},
    ).scalar_one()

    ledger_count = db_connection.execute(
        text("""
            SELECT COUNT(*)
            FROM ledger_entries
        """)
    ).scalar_one()

    assert transaction_count == 1
    assert ledger_count == 2
