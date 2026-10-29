
from decimal import Decimal

from sqlalchemy.orm import Session

from models import Account, OperatorWallet


def test_payment_rejected_when_balance_is_insufficient(
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

    # Set the passenger's balance to less than the requested fare.
    with Session(
        bind=db_connection,
        autoflush=False,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    ) as db:
        account = db.get(Account, test_data["account_id"])
        wallet = db.get(OperatorWallet, test_data["wallet_id"])

        assert account is not None
        assert wallet is not None

        account.balance = Decimal("20.00")
        db.commit()

    # Record balances before payment.
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

    # Attempt to pay more than the passenger can afford.
    payload = {
        "card_uid": test_data["card_uid"],
        "amount": "50.00",
        "request_id": "insufficient-balance-test",
    }

    response = client.post(
        "/payments",
        json=payload,
        headers=headers,
    )

    # The payment should be rejected.
    assert response.status_code in (400, 409, 422), response.text

    # Verify that neither balance changed.
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
