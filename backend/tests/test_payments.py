from uuid import uuid4


def make_payment(
    client,
    headers,
    card_uid="04A1B2C3D4",
    amount="50.00",
    request_id=None,
):
    """Send a fare payment request."""
    return client.post(
        "/payments",
        headers=headers,
        json={
            "card_uid": card_uid,
            "amount": amount,
            "request_id": request_id or str(uuid4()),
        },
    )


def get_record_count(db_connection, table):
    """Return the number of records in a payment-related table."""
    result = db_connection.exec_driver_sql(
        f"SELECT COUNT(*) FROM {table}"
    )
    return result.scalar_one()


def test_payment_success(authenticated_operator, client):
    headers = authenticated_operator["headers"]

    response = make_payment(
        client,
        headers,
        amount="50.00",
    )

    assert response.status_code == 200, response.text

    body = response.json()

    assert body["status"] == "completed"
    assert body["amount"] == "50.00"
    assert body["passenger_balance"] == "450.00"
    assert body["operator_balance"] == "50.00"
    assert "transaction_id" in body


def test_payment_updates_passenger_and_operator_balances(
    authenticated_operator,
    client,
    db_connection,
):
    data = authenticated_operator["data"]

    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="75.00",
    )

    assert response.status_code == 200, response.text

    passenger_balance = db_connection.exec_driver_sql(
        "SELECT balance FROM accounts WHERE id = %s"
        % data["account_id"]
    ).scalar_one()

    operator_balance = db_connection.exec_driver_sql(
        "SELECT balance FROM operator_wallets WHERE id = %s"
        % data["wallet_id"]
    ).scalar_one()

    assert str(passenger_balance) == "425.00"
    assert str(operator_balance) == "75.00"


def test_payment_creates_transaction(
    authenticated_operator,
    client,
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

    transaction = db_connection.exec_driver_sql(
        """
        SELECT account_id, card_id, operator_id, amount, status
        FROM transactions
        WHERE id = %s
        """ % transaction_id
    ).mappings().one()

    assert transaction["account_id"] == data["account_id"]
    assert transaction["card_id"] == data["card_id"]
    assert transaction["operator_id"] == data["operator_id"]
    assert str(transaction["amount"]) == "50.00"
    assert transaction["status"] == "completed"


def test_payment_creates_two_ledger_entries(
    authenticated_operator,
    client,
    db_connection,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="50.00",
    )

    assert response.status_code == 200, response.text

    transaction_id = response.json()["transaction_id"]

    entries = db_connection.exec_driver_sql(
        """
        SELECT entry_type, amount, balance_after
        FROM ledger_entries
        WHERE transaction_id = %s
        ORDER BY entry_type
        """ % transaction_id
    ).mappings().all()

    assert len(entries) == 2

    entries_by_type = {
        entry["entry_type"]: entry
        for entry in entries
    }

    debit = entries_by_type["debit"]
    credit = entries_by_type["credit"]

    assert str(debit["amount"]) == "-50.00"
    assert str(debit["balance_after"]) == "450.00"

    assert str(credit["amount"]) == "50.00"
    assert str(credit["balance_after"]) == "50.00"


def test_payment_insufficient_balance(
    authenticated_operator,
    client,
    db_connection,
):
    data = authenticated_operator["data"]

    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="600.00",
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Insufficient passenger balance"
    )

    passenger_balance = db_connection.exec_driver_sql(
        "SELECT balance FROM accounts WHERE id = %s"
        % data["account_id"]
    ).scalar_one()

    operator_balance = db_connection.exec_driver_sql(
        "SELECT balance FROM operator_wallets WHERE id = %s"
        % data["wallet_id"]
    ).scalar_one()

    assert str(passenger_balance) == "500.00"
    assert str(operator_balance) == "0.00"

    assert get_record_count(db_connection, "transactions") == 0
    assert get_record_count(db_connection, "ledger_entries") == 0


def test_payment_with_unknown_card(
    authenticated_operator,
    client,
    db_connection,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        card_uid="UNKNOWN123",
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Active NFC card not found"

    assert get_record_count(db_connection, "transactions") == 0
    assert get_record_count(db_connection, "ledger_entries") == 0


def test_payment_with_inactive_card(
    authenticated_operator,
    client,
    db_connection,
    test_data,
):
    db_connection.exec_driver_sql(
        """
        UPDATE nfc_cards
        SET is_active = FALSE
        WHERE id = %s
        """ % test_data["card_id"]
    )

    response = make_payment(
        client,
        authenticated_operator["headers"],
    )

    assert response.status_code == 404
    assert response.json()["detail"] == "Active NFC card not found"

    assert get_record_count(db_connection, "transactions") == 0


def test_payment_with_inactive_passenger_account(
    authenticated_operator,
    client,
    db_connection,
    test_data,
):
    db_connection.exec_driver_sql(
        """
        UPDATE accounts
        SET is_active = FALSE
        WHERE id = %s
        """ % test_data["account_id"]
    )

    response = make_payment(
        client,
        authenticated_operator["headers"],
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Passenger account is unavailable"
    )

    assert get_record_count(db_connection, "transactions") == 0


def test_payment_with_inactive_operator(
    authenticated_operator,
    client,
    db_connection,
    test_data,
):
    db_connection.exec_driver_sql(
        """
        UPDATE operators
        SET is_active = FALSE
        WHERE id = %s
        """ % test_data["operator_id"]
    )

    response = make_payment(
        client,
        authenticated_operator["headers"],
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid or expired access token"

    assert get_record_count(db_connection, "transactions") == 0


def test_payment_with_inactive_operator_wallet(
    authenticated_operator,
    client,
    db_connection,
    test_data,
):
    db_connection.exec_driver_sql(
        """
        UPDATE operator_wallets
        SET is_active = FALSE
        WHERE id = %s
        """ % test_data["wallet_id"]
    )

    response = make_payment(
        client,
        authenticated_operator["headers"],
    )

    assert response.status_code == 400
    assert response.json()["detail"] == (
        "Operator wallet is unavailable"
    )

    assert get_record_count(db_connection, "transactions") == 0


def test_duplicate_payment_request(
    authenticated_operator,
    client,
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
    assert second_response.json()["detail"] == (
        "This payment request has already been processed"
    )

    assert get_record_count(db_connection, "transactions") == 1
    assert get_record_count(db_connection, "ledger_entries") == 2


def test_zero_fare_rejected(authenticated_operator, client):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="0.00",
    )

    assert response.status_code == 422


def test_negative_fare_rejected(authenticated_operator, client):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="-10.00",
    )

    assert response.status_code == 422


def test_fare_with_more_than_two_decimal_places(
    authenticated_operator,
    client,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="10.555",
    )

    assert response.status_code == 422


def test_invalid_request_id_rejected(
    authenticated_operator,
    client,
):
    response = make_payment(
        client,
        authenticated_operator["headers"],
        request_id="not-a-valid-uuid",
    )

    assert response.status_code == 422


def test_payment_without_authentication(client):
    response = client.post(
        "/payments",
        json={
            "card_uid": "04A1B2C3D4",
            "amount": "50.00",
            "request_id": str(uuid4()),
        },
    )

    assert response.status_code == 401
