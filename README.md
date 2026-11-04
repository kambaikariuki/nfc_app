# nfc_app

A Flutter mobile application for an NFC-based cashless fare collection system for matatus in Nairobi, Kenya.

The application allows passengers to manage their accounts and view transactions, while operators can manage their wallets, prompt fare payments, and view payment history.


## Setup

1. Clone the repo onto your system.

`git clone https://kambaikariuki/nfc_app.git`


2. Ensure that you have `flutter` on your system. Run `flutter doctor` to ensure everything is working well.

`flutter doctor`

3. To run the flutter application, open a terminal in the root directory of the project and run: 

`flutter run`

4. To run the server for the backend, open a terminal in the `backend` directory.

5. Ensure you have `uv` running on your system. Run `uv --version` to confirm. If you don't have `uv` run the following command to install it:

  `curl -LsSf https://astral.sh/uv/install.sh | sh`

6. To get all the dependencies, run:

`uv sync`

7. Run `uv fastapi run dev` to start the development server.

