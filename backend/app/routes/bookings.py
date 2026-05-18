import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.booking import Booking
from app.models.trip import Trip
from app.schemas.booking import BookingCreate, BookingResponse

router = APIRouter()


@router.post("/", response_model=BookingResponse, status_code=201)
async def create_booking(
    payload: BookingCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    trip_result = await db.execute(
        select(Trip).where(Trip.id == payload.trip_id, Trip.user_id == uuid.UUID(user_id))
    )
    if not trip_result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Voyage introuvable")

    booking = Booking(**payload.model_dump())
    db.add(booking)
    await db.flush()
    await db.refresh(booking)
    return booking


@router.get("/", response_model=List[BookingResponse])
async def list_bookings(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Booking)
        .join(Trip)
        .where(Trip.user_id == uuid.UUID(user_id))
        .order_by(Booking.created_at.desc())
    )
    return result.scalars().all()


@router.get("/{booking_id}", response_model=BookingResponse)
async def get_booking(
    booking_id: uuid.UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Booking).join(Trip).where(
            Booking.id == booking_id,
            Trip.user_id == uuid.UUID(user_id),
        )
    )
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Réservation introuvable")
    return booking
