from uuid import uuid4

from sqlalchemy import text


def make_payment(client, headers, amount="50.00"):
    """Create a payment to populate passenger transaction history."""
    return client.post(
        "/payments",
        headers=headers,
        json={
            "card_uid": "04A1B2C3D4",
            "amount": amount,
            "request_id": str(uuid4()),
        },
    )


def test_get_passenger_balance(
    client,
    authenticated_passenger,
):
    response = client.get(
        "/passengers/balance",
        headers=authenticated_passenger["headers"],
    )

    assert response.status_code == 200, response.text

    body = response.json()

    # Adjust this assertion if your endpoint uses a different key.
    assert body["balance"] == "500.00"


def test_get_passenger_balance_without_authentication(client):
    response = client.get("/passengers/balance")

    assert response.status_code == 401


def test_operator_cannot_access_passenger_balance(
    client,
    authenticated_operator,
):
    response = client.get(
        "/passengers/balance",
        headers=authenticated_operator["headers"],
    )

    assert response.status_code == 403


def test_get_passenger_transaction_history(
    client,
    authenticated_operator,
    authenticated_passenger,
):
    payment_response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="50.00",
    )

    assert payment_response.status_code == 200, payment_response.text

    response = client.get(
        "/passengers/transactions",
        headers=authenticated_passenger["headers"],
    )

    assert response.status_code == 200, response.text

    transactions = response.json()

    assert len(transactions) == 1
    assert transactions[0]["amount"] == "50.00"


def test_empty_passenger_transaction_history(
    client,
    authenticated_passenger,
):
    response = client.get(
        "/passengers/transactions",
        headers=authenticated_passenger["headers"],
    )

    assert response.status_code == 200, response.text
    assert response.json() == []


def test_passenger_cannot_access_another_passengers_balance(
    client,
    authenticated_passenger,
    db_connection,
):
    # Create a second passenger and account.
    result = db_connection.execute(
        text("""
            INSERT INTO passengers (
                full_name,
                email,
                password_hash
            )
            VALUES (
                'Another Passenger',
                'another@test.com',
                'unused-test-password-hash'
            )
            RETURNING id
        """)
    )

    other_passenger_id = result.scalar_one()

    db_connection.execute(
        text("""
            INSERT INTO accounts (
                passenger_id,
                balance,
                is_active
            )
            VALUES (
                :passenger_id,
                1000.00,
                TRUE
            )
        """),
        {"passenger_id": other_passenger_id},
    )

    # The endpoint should use the authenticated passenger's ID,
    # not an ID supplied by the client.
    response = client.get(
        f"/passengers/balance?passenger_id={other_passenger_id}",
        headers=authenticated_passenger["headers"],
    )

    assert response.status_code == 200, response.text

    # The authenticated passenger should still see their own balance.
    assert response.json()["balance"] == "500.00"
