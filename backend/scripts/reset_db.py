from sqlalchemy import text

from database import engine


TABLES = """
    TRUNCATE TABLE
        ledger_entries,
        transactions,
        nfc_cards,
        operator_wallets,
        accounts,
        passengers,
        operators
    RESTART IDENTITY CASCADE
"""


def reset_database():
    try:
        with engine.begin() as connection:
            connection.execute(text(TABLES))

        print("Database data cleared successfully.")
        print("Tables and Alembic migration history preserved.")

    except Exception as error:
        print(f"Database reset failed: {error}")
        raise


if __name__ == "__main__":
    reset_database()
