from fastapi import Depends, FastAPI, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from routers import payments, authentication, passengers, operators

app = FastAPI(title="NFC Fare Collection API")

app.include_router(authentication.router)
app.include_router(payments.router)
app.include_router(passengers.router)
app.include_router(operators.router)

# Authentication DONE
# Payments DONE
# Passengers DONE
# Operators


@app.get("/")
def read_root():
    return {"message": "NFC Fare Collection API is running"}
