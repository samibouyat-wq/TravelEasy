import uuid
from datetime import datetime, date
from typing import Optional, Any

from pydantic import BaseModel

from app.models.trip import TripStatus, TransportType


class TripCreate(BaseModel):
    title: str
    origin_city: str
    destination_city: str
    departure_date: date
    return_date: Optional[date] = None
    num_travelers: int = 1
    budget_min: float
    budget_max: float
    transport_type: TransportType = TransportType.TRAIN
    notes: Optional[str] = None


class TripUpdate(BaseModel):
    title: Optional[str] = None
    notes: Optional[str] = None
    status: Optional[TripStatus] = None


class TripResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    origin_city: str
    destination_city: str
    departure_date: date
    return_date: Optional[date]
    num_travelers: int
    budget_min: float
    budget_max: float
    transport_type: TransportType
    status: TripStatus
    ai_proposals: Optional[Any]
    created_at: datetime

    class Config:
        from_attributes = True
