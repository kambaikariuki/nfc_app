# MatPay

MatPay is a Flutter mobile application for an NFC-based cashless fare collection system for matatus in Nairobi, Kenya.

Powered by a FastAPI backend and PostgreSQL, MatPay allows passengers to pay their fares using NFC cards linked to their mobile accounts. Passengers simply tap their NFC cards against an operator's NFC-enabled smartphone to complete a fare payment.

[Backend API.](https://nfc-app-p9pi.onrender.com) Hosted on [Render.](https://render.com/)

**[Technical walkthrough video](https://drive.google.com/file/d/131i0MXGoejgZCOZashEm1oCWEInhr-eo/view?usp=sharing)**


## Features

#### Passenger
- Passenger registration and authentication.

- Link NFC cards to passenger accounts.

- View account balance.

- View transaction history.

- Pay matatu fares using NFC cards.

- Manage active NFC cards.
  
#### Operator
- Operator registration and authentication.

- Prompt fare payment.

- Receive payment into directly into wallet.

- View wallet balance.

- View transaction history.
  

## Technologies

- Flutter
- FastAPI
- PostgreSQL

## Prerequisites

Before setting up the project, ensure you have:

- Flutter SDK

- Dart SDK (included with Flutter)

- Python 3.12 or later

- uv package manager

- Git

- PostgreSQL (only if running your own local backend)

For NFC functionality, an NFC-compatible Android device is also required.

# Installation

**1. Clone the repo onto your system.**

```bash
git clone https://github.com/kambaikariuki/nfc_app.git
cd nfc_app
```

**2. Setup Flutter application.**

Ensure Flutter is installed and configured:

```bash
flutter doctor
```
Get dependencies:

```bash
flutter pub get
```

Run the application:
```bash
flutter run --web-port 5000
```

# Run backend locally

### 1. Setup database ###

Navigate to the backend directory:

```bash
cd backend
```

Connect to postgres.


```bash
psql -U postgres

```

At the `postgres=#` prompt, create the database:

```SQL
CREATE DATABASE nfc_app_db;
```

Connect to the new database:
```SQL
\c nfc_app_db
```

Create a dedicated database user and grant database privileges:

```SQL
CREATE USER nfc_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE nfc_app_db TO _nfc_user;
```

Connect to the database as the new user and grant schema privileges:

```SQL
GRANT ALL ON SCHEMA public TO nfc_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO nfc_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO nfc_user;
```

### 2. Configure environment variables ###

Inside the `backend` directory, use the `.sample.env` to create your `.env` file. Replace `db_user` and `db_password` with your database user and password.

```
DATABASE_URL=postgresql+psycopg://db_user:db_password@localhost:5432/nfc_app_db
JWT_SECRET_KEY=secret_key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

To generate the `JWT_SECRET_KEY` run:

```
python -c "import secrets; print(secrets.token_hex(32))"
```


### 3. Install dependencies ###

Ensure uv is installed:

```python
uv --version
```

If you don't have uv, install it on Linux/macOS using:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

On Windows PowerShell, use:

```
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

Install the backend dependencies:

```
uv sync
```

### 4. Run database migrations ###

Create database tables using migrations:

```
uv run alembic upgrade head
```


### 5. Start the development server ###

Run the API locally:

```
uv run fastapi dev
```

The API will be available at:

```
http://127.0.01:8000
```

API documentation:

```
http://127:0.0.1:8000/docs
```

# License #

This project is developed as an academic/software engineering project.





