import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.models.payment import PaymentStatus


class PaymentIntentCreate(BaseModel):
    booking_id: uuid.UUID
    amount: float
    currency: str = "EUR"


class PaymentIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str
    amount: float
    currency: str


class PaymentResponse(BaseModel):
    id: uuid.UUID
    booking_id: uuid.UUID
    amount: float
    currency: str
    status: PaymentStatus
    created_at: datetime

    class Config:
        from_attributes = True
