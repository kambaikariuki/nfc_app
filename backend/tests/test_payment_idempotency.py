
from uuid import uuid4
from decimal import Decimal

from sqlalchemy.orm import Session

from models import Account, OperatorWallet


def test_duplicate_payment_does_not_transfer_twice(
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

    passenger_token = passenger_login.json()["access_token"]
    passenger_headers = {
        "Authorization": f"Bearer {passenger_token}"
    }

    # Record balances before payment.
    passenger_balance_response = client.get(
        "/passengers/balance",
        headers=passenger_headers,
    )
    operator_wallet_response = client.get(
        "/operators/wallet",
        headers=headers,
    )

    assert passenger_balance_response.status_code == 200, (
        passenger_balance_response.text
    )
    assert operator_wallet_response.status_code == 200, (
        operator_wallet_response.text
    )

    passenger_balance_before = Decimal(
        str(passenger_balance_response.json()["balance"])
    )
    operator_balance_before = Decimal(
        str(operator_wallet_response.json()["balance"])
    )

    # Submit the same payment request twice.
    payload = {
        "card_uid": test_data["card_uid"],
        "amount": "50.00",
        "request_id": str(uuid4()),
    }

    first = client.post(
        "/payments",
        json=payload,
        headers=headers,
    )
    assert first.status_code == 200, first.text

    second = client.post(
        "/payments",
        json=payload,
        headers=headers,
    )
    assert second.status_code == 409, second.text

    # Read the final balances from the test database.
    with Session(
        bind=db_connection,
        autoflush=False,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    ) as db:
        passenger_account = db.get(
            Account,
            test_data["account_id"],
        )
        operator_wallet = db.get(
            OperatorWallet,
            test_data["wallet_id"],
        )

        assert passenger_account is not None
        assert operator_wallet is not None

        passenger_balance_after = Decimal(
            str(passenger_account.balance)
        )
        operator_balance_after = Decimal(
            str(operator_wallet.balance)
        )

    # Verify that the fare was transferred exactly once.
    assert (
        passenger_balance_before - passenger_balance_after
        == Decimal("50.00")
    )
    assert (
        operator_balance_after - operator_balance_before
        == Decimal("50.00")
    )
