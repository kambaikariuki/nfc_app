
from decimal import Decimal
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from models import Account, OperatorWallet


@pytest.mark.parametrize(
    "amount",
    [
        "0.00",
        "-10.00",
    ],
)
def test_payment_rejected_for_invalid_fare_amount(
    amount,
    client,
    test_data,
    authenticated_operator,
    db_connection,
):
    headers = authenticated_operator["headers"]

    # Authenticate the passenger.
    passenger_login = client.post(
        "/auth/passenger/login",
        json={
            "email": test_data["passenger_email"],
            "password": test_data["passenger_password"],
        },
    )
    assert passenger_login.status_code == 200, passenger_login.text

    passenger_headers = {
        "Authorization": (
            f"Bearer {passenger_login.json()['access_token']}"
        )
    }

    # Record balances before attempting payment.
    passenger_balance_response = client.get(
        "/passengers/balance",
        headers=passenger_headers,
    )
    operator_wallet_response = client.get(
        "/operators/wallet",
        headers=headers,
    )

    assert passenger_balance_response.status_code == 200
    assert operator_wallet_response.status_code == 200

    passenger_balance_before = Decimal(
        str(passenger_balance_response.json()["balance"])
    )
    operator_balance_before = Decimal(
        str(operator_wallet_response.json()["balance"])
    )

    # Attempt payment using an invalid fare.
    payload = {
        "card_uid": test_data["card_uid"],
        "amount": amount,
        "request_id": str(uuid4()),
    }

    response = client.post(
        "/payments",
        json=payload,
        headers=headers,
    )

    # Invalid fares must be rejected.
    assert response.status_code in (400, 422), response.text

    # Confirm neither balance changed.
    passenger_balance_after = client.get(
        "/passengers/balance",
        headers=passenger_headers,
    )
    operator_wallet_after = client.get(
        "/operators/wallet",
        headers=headers,
    )

    assert passenger_balance_after.status_code == 200
    assert operator_wallet_after.status_code == 200

    assert Decimal(
        str(passenger_balance_after.json()["balance"])
    ) == passenger_balance_before

    assert Decimal(
        str(operator_wallet_after.json()["balance"])
    ) == operator_balance_before
