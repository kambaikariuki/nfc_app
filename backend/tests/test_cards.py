def get_passenger_headers(client, test_data):
    """Log in a passenger and return their authorization headers."""
    response = client.post(
        "/auth/passenger/login",
        json={
            "email": test_data["passenger_email"],
            "password": test_data["passenger_password"],
        },
    )

    assert response.status_code == 200, response.text

    token = response.json()["access_token"]

    return {"Authorization": f"Bearer {token}"}

def test_link_card_duplicate_uid(client, test_data):
    headers = get_passenger_headers(client, test_data)

    # This UID already belongs to the passenger created by test_data.
    response = client.post(
        "/cards/register",
        headers=headers,
        json={"uid": test_data["card_uid"]},
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "This NFC card is already registered or in use."
    )

def test_passenger_cannot_link_second_active_card(
    client,
    test_data,
):
    headers = get_passenger_headers(client, test_data)

    # test_data already creates an active card for this passenger.
    response = client.post(
        "/cards/register",
        headers=headers,
        json={"uid": "04FF112233"},
    )

    assert response.status_code == 409
    assert response.json()["detail"] == (
        "You already have an active card. "
        "Deactivate it before registering a replacement."
    )

def test_link_card_without_authentication(client):
    response = client.post(
        "/cards/register",
        json={"uid": "04FF112233"},
    )

    # HTTPBearer returns 401 when credentials are missing.
    assert response.status_code == 401

def test_operator_cannot_link_passenger_card(client, test_data):
    login_response = client.post(
        "/auth/operator/login",
        json={
            "email": test_data["operator_email"],
            "password": test_data["operator_password"],
        },
    )

    assert login_response.status_code == 200

    token = login_response.json()["access_token"]

    response = client.post(
        "/cards/register",
        headers={"Authorization": f"Bearer {token}"},
        json={"uid": "04FF112233"},
    )

    assert response.status_code == 403
