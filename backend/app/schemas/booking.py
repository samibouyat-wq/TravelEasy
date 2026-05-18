import uuid
from datetime import datetime
from typing import Optional, Any

from pydantic import BaseModel

from app.models.booking import BookingType, BookingStatus


class BookingCreate(BaseModel):
    trip_id: uuid.UUID
    booking_type: BookingType
    provider: str
    amount: float
    currency: str = "EUR"
    details: Optional[Any] = None


class BookingResponse(BaseModel):
    id: uuid.UUID
    trip_id: uuid.UUID
    booking_type: BookingType
    status: BookingStatus
    provider: str
    amount: float
    currency: str
    confirmation_code: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
