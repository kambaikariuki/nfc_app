import pytest


def login(client, role, email, password):
    """Log in as a passenger or operator."""
    return client.post(
        f"/auth/{role}/login",
        json={
            "email": email,
            "password": password,
        },
    )


@pytest.mark.parametrize(
    ("role", "email_key", "password_key"),
    [
        ("passenger", "passenger_email", "passenger_password"),
        ("operator", "operator_email", "operator_password"),
    ],
)
def test_login_success(client, test_data, role, email_key, password_key):
    response = login(
        client,
        role,
        test_data[email_key],
        test_data[password_key],
    )

    assert response.status_code == 200

    body = response.json()
    assert "access_token" in body
    assert body["access_token"]
    assert body["token_type"] == "bearer"


@pytest.mark.parametrize(
    ("role", "email_key"),
    [
        ("passenger", "passenger_email"),
        ("operator", "operator_email"),
    ],
)
def test_login_wrong_password(client, test_data, role, email_key):
    response = login(
        client,
        role,
        test_data[email_key],
        "WrongPassword123!",
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"


@pytest.mark.parametrize("role", ["passenger", "operator"])
def test_login_nonexistent_email(client, role):
    response = login(
        client,
        role,
        "doesnotexist@test.com",
        "SomePassword123!",
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"


def test_auth_me_with_valid_passenger_token(
    client,
    test_data,
):
    login_response = login(
        client,
        "passenger",
        test_data["passenger_email"],
        test_data["passenger_password"],
    )

    assert login_response.status_code == 200

    token = login_response.json()["access_token"]

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()


def test_auth_me_with_valid_operator_token(
    client,
    test_data,
):
    login_response = login(
        client,
        "operator",
        test_data["operator_email"],
        test_data["operator_password"],
    )

    assert login_response.status_code == 200

    token = login_response.json()["access_token"]

    response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()


def test_auth_me_without_token(client):
    response = client.get("/auth/me")

    # HTTPBearer returns 401 when credentials are missing.
    assert response.status_code == 401


def test_auth_me_with_invalid_token(client):
    response = client.get(
        "/auth/me",
        headers={"Authorization": "Bearer invalid.token.value"},
    )

    assert response.status_code == 401


def test_passenger_cannot_access_operator_wallet(
    client,
    test_data,
):
    login_response = login(
        client,
        "passenger",
        test_data["passenger_email"],
        test_data["passenger_password"],
    )

    assert login_response.status_code == 200

    token = login_response.json()["access_token"]

    response = client.get(
        "/operators/wallet",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 403
