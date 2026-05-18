import uuid
from typing import List

from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.trip import Trip
from app.schemas.trip import TripCreate, TripUpdate, TripResponse
from app.services.ai_service import generate_trip_proposals
from app.services.transport_service import search_transports
from app.services.hotel_service import search_hotels

router = APIRouter()


@router.post("/", response_model=TripResponse, status_code=201)
async def create_trip(
    payload: TripCreate,
    background_tasks: BackgroundTasks,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    trip = Trip(**payload.model_dump(), user_id=uuid.UUID(user_id))
    db.add(trip)
    await db.flush()
    await db.refresh(trip)

    background_tasks.add_task(generate_trip_proposals, trip_id=str(trip.id))
    return trip


@router.get("/", response_model=List[TripResponse])
async def list_trips(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Trip).where(Trip.user_id == uuid.UUID(user_id)).order_by(Trip.created_at.desc())
    )
    return result.scalars().all()


@router.get("/{trip_id}", response_model=TripResponse)
async def get_trip(
    trip_id: uuid.UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Trip).where(Trip.id == trip_id, Trip.user_id == uuid.UUID(user_id))
    )
    trip = result.scalar_one_or_none()
    if not trip:
        raise HTTPException(status_code=404, detail="Voyage introuvable")
    return trip


@router.patch("/{trip_id}", response_model=TripResponse)
async def update_trip(
    trip_id: uuid.UUID,
    payload: TripUpdate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Trip).where(Trip.id == trip_id, Trip.user_id == uuid.UUID(user_id))
    )
    trip = result.scalar_one_or_none()
    if not trip:
        raise HTTPException(status_code=404, detail="Voyage introuvable")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(trip, field, value)

    await db.flush()
    await db.refresh(trip)
    return trip


@router.delete("/{trip_id}", status_code=204)
async def delete_trip(
    trip_id: uuid.UUID,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Trip).where(Trip.id == trip_id, Trip.user_id == uuid.UUID(user_id))
    )
    trip = result.scalar_one_or_none()
    if not trip:
        raise HTTPException(status_code=404, detail="Voyage introuvable")
    await db.delete(trip)
