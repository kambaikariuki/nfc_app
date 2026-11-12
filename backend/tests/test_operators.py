from uuid import uuid4

def make_payment(client, headers, amount="50.00"):
    """Create a payment to populate operator transaction history."""
    return client.post(
        "/payments",
        headers=headers,
        json={
            "card_uid": "04A1B2C3D4",
            "amount": amount,
            "request_id": str(uuid4()),
        },
    )


def test_get_operator_wallet(
    client,
    authenticated_operator,
):
    response = client.get(
        "/operators/wallet",
        headers=authenticated_operator["headers"],
    )

    assert response.status_code == 200, response.text

    body = response.json()

    assert body["operator_id"] == authenticated_operator["data"]["operator_id"]
    assert body["balance"] == "0.00"
    assert body["is_active"] is True


def test_get_operator_wallet_without_authentication(client):
    response = client.get("/operators/wallet")

    assert response.status_code == 401


def test_passenger_cannot_access_operator_wallet(
    client,
    authenticated_passenger,
):
    response = client.get(
        "/operators/wallet",
        headers=authenticated_passenger["headers"],
    )

    assert response.status_code == 403


def test_get_operator_transaction_history(
    client,
    authenticated_operator,
    authenticated_passenger,
):
    # Create a fare payment.
    payment_response = make_payment(
        client,
        authenticated_operator["headers"],
        amount="50.00",
    )

    assert payment_response.status_code == 200, payment_response.text

    # Retrieve the operator's transactions.
    response = client.get(
        "/operators/transactions",
        headers=authenticated_operator["headers"],
    )

    assert response.status_code == 200, response.text

    transactions = response.json()

    assert len(transactions) == 1

    transaction = transactions[0]

    assert transaction["passenger_name"] == "Test Passenger"
    assert transaction["operator_id"] == authenticated_operator["data"]["operator_id"]
    assert transaction["amount"] == "50.00"
    assert transaction["status"] == "completed"
    assert transaction["transaction_id"] == payment_response.json()["transaction_id"]
    assert transaction["created_at"] is not None


def test_empty_operator_transaction_history(
    client,
    authenticated_operator,
):
    response = client.get(
        "/operators/transactions",
        headers=authenticated_operator["headers"],
    )

    assert response.status_code == 200, response.text
    assert response.json() == []


def test_passenger_cannot_access_operator_transactions(
    client,
    authenticated_passenger,
):
    response = client.get(
        "/operators/transactions",
        headers=authenticated_passenger["headers"],
    )

    assert response.status_code == 403
