import uuid

import stripe
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.models.booking import Booking
from app.models.payment import Payment, PaymentStatus
from app.schemas.payment import PaymentIntentCreate, PaymentIntentResponse, PaymentResponse

stripe.api_key = settings.STRIPE_SECRET_KEY
router = APIRouter()


@router.post("/create-intent", response_model=PaymentIntentResponse)
async def create_payment_intent(
    payload: PaymentIntentCreate,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    booking_result = await db.execute(
        select(Booking).where(Booking.id == payload.booking_id)
    )
    booking = booking_result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Réservation introuvable")

    intent = stripe.PaymentIntent.create(
        amount=int(payload.amount * 100),
        currency=payload.currency.lower(),
        metadata={"booking_id": str(payload.booking_id), "user_id": user_id},
    )

    payment = Payment(
        booking_id=payload.booking_id,
        stripe_payment_intent_id=intent.id,
        amount=payload.amount,
        currency=payload.currency,
    )
    db.add(payment)

    return PaymentIntentResponse(
        client_secret=intent.client_secret,
        payment_intent_id=intent.id,
        amount=payload.amount,
        currency=payload.currency,
    )


@router.post("/webhook")
async def stripe_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except Exception:
        raise HTTPException(status_code=400, detail="Signature webhook invalide")

    if event["type"] == "payment_intent.succeeded":
        pi = event["data"]["object"]
        result = await db.execute(
            select(Payment).where(Payment.stripe_payment_intent_id == pi["id"])
        )
        payment = result.scalar_one_or_none()
        if payment:
            payment.status = PaymentStatus.SUCCEEDED
            payment.stripe_charge_id = pi.get("latest_charge")

    elif event["type"] == "payment_intent.payment_failed":
        pi = event["data"]["object"]
        result = await db.execute(
            select(Payment).where(Payment.stripe_payment_intent_id == pi["id"])
        )
        payment = result.scalar_one_or_none()
        if payment:
            payment.status = PaymentStatus.FAILED

    return {"received": True}
