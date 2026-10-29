from fastapi import FastAPI

from routers import payments, authentication, passengers, operators, cards

app = FastAPI(title="NFC Fare Collection API")

from fastapi.middleware.cors import CORSMiddleware


app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(authentication.router)
app.include_router(payments.router)
app.include_router(passengers.router)
app.include_router(operators.router)
app.include_router(cards.router)

@app.get("/")
def read_root():
    return {"message": "NFC Fare Collection API is running"}
