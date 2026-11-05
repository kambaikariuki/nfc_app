# MatPay

MatPay is a Flutter mobile application for an NFC-based cashless fare collection system for matatus in Nairobi, Kenya.

Powered by a FastAPI backend and PostgreSQL, MatPay allows passengers to pay their fares using NFC cards linked to their mobile accounts. Passengers simply tap their NFC cards against an operator's NFC-enabled smartphone to complete a fare payment.

[Backend API.](https://nfc-app-p9pi.onrender.com) Hosted on [Render.](https://render.com/)


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
flutter run
```

# Run backend locally

**1. Setup database**

Using Postgres, create a new database for the application

