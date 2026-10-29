
from decimal import Decimal
from uuid import uuid4

from sqlalchemy.orm import Session

from models import Account, NfcCard, OperatorWallet


def test_payment_rejected_for_inactive_nfc_card(
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

    # Deactivate the NFC card in the test database.
    with Session(
        bind=db_connection,
        autoflush=False,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    ) as db:
        card = db.get(NfcCard, test_data["card_id"])
        assert card is not None

        card.is_active = False
        db.commit()

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

    # Attempt payment using the inactive card.
    payload = {
        "card_uid": test_data["card_uid"],
        "amount": "50.00",
        "request_id": str(uuid4()),
    }

    response = client.post(
        "/payments",
        json=payload,
        headers=headers,
    )

    # The inactive card must not be accepted.
    assert response.status_code in (400, 403, 404, 409), response.text

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
