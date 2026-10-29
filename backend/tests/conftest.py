
import os
import sys
from pathlib import Path

import pytest
from dotenv import load_dotenv
from fastapi.testclient import TestClient
from pwdlib import PasswordHash
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

BACKEND_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(BACKEND_DIR))

load_dotenv()

TEST_DATABASE_URL = os.getenv("DATABASE_URL_TEST")

if not TEST_DATABASE_URL:
    raise RuntimeError("DATABASE_URL_TEST is missing from .env")

test_engine = create_engine(
    TEST_DATABASE_URL,
    pool_pre_ping=True,
)

with test_engine.connect() as connection:
    database_name = connection.execute(
        text("SELECT current_database()")
    ).scalar_one()

if database_name != "nfc_fare_test":
    test_engine.dispose()
    raise RuntimeError(
        f"Refusing to run tests against '{database_name}'. "
        "Expected 'nfc_fare_test'."
    )

from database import get_db
from main import app
from models import (
    Account,
    NfcCard,
    Operator,
    OperatorWallet,
    Passenger,
)

password_hasher = PasswordHash.recommended()


@pytest.fixture
def db_connection():
    connection = test_engine.connect()
    outer_transaction = connection.begin()

    try:
        yield connection
    finally:
        if outer_transaction.is_active:
            outer_transaction.rollback()

        connection.close()


@pytest.fixture
def test_data(db_connection):
    TestSession = sessionmaker(
        bind=db_connection,
        autoflush=False,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )

    db = TestSession()

    try:
        passenger = Passenger(
            full_name="Test Passenger",
            email="passenger@test.com",
            password_hash=password_hasher.hash(
                "Passenger123!"
            ),
        )
        operator = Operator(
            full_name="Test Operator",
            email="operator@test.com",
            password_hash=password_hasher.hash(
                "Operator123!"
            ),
            is_active=True,
        )

        db.add_all([passenger, operator])
        db.flush()

        account = Account(
            passenger_id=passenger.id,
            balance=500.00,
            is_active=True,
        )
        card = NfcCard(
            uid="04A1B2C3D4",
            passenger_id=passenger.id,
            is_active=True,
        )
        wallet = OperatorWallet(
            operator_id=operator.id,
            balance=0.00,
            is_active=True,
        )

        db.add_all([account, card, wallet])
        db.flush()

        data = {
            "passenger_id": passenger.id,
            "operator_id": operator.id,
            "account_id": account.id,
            "card_id": card.id,
            "wallet_id": wallet.id,
            "passenger_email": "passenger@test.com",
            "passenger_password": "Passenger123!",
            "operator_email": "operator@test.com",
            "operator_password": "Operator123!",
            "card_uid": "04A1B2C3D4",
        }

        # Release the setup savepoint while preserving the
        # outer transaction, which will be rolled back later.
        db.commit()

        yield data

    finally:
        db.close()


@pytest.fixture
def client(db_connection):
    TestSession = sessionmaker(
        bind=db_connection,
        autoflush=False,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )

    def override_get_db():
        db = TestSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        app.dependency_overrides.pop(get_db, None)


@pytest.fixture
def authenticated_operator(client, test_data):
    response = client.post(
        "/auth/operator/login",
        json={
            "email": test_data["operator_email"],
            "password": test_data["operator_password"],
        },
    )

    assert response.status_code == 200, response.text

    body = response.json()

    # Adjust this if your login response uses a different key.
    token = body.get("access_token")
    assert token, f"No access_token in login response: {body}"

    return {
        "headers": {"Authorization": f"Bearer {token}"},
        "data": test_data,
    }
