import uuid

import stripe
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
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


class CheckoutSessionRequest(BaseModel):
    trip_id: str
    trip_title: str
    amount: float
    currency: str = "eur"


class CheckoutSessionResponse(BaseModel):
    checkout_url: str


@router.post("/create-checkout-session", response_model=CheckoutSessionResponse)
async def create_checkout_session(
    payload: CheckoutSessionRequest,
    user_id: str = Depends(get_current_user_id),
):
    try:
        session = stripe.checkout.Session.create(
            payment_method_types=["card"],
            line_items=[
                {
                    "price_data": {
                        "currency": payload.currency,
                        "product_data": {
                            "name": payload.trip_title,
                            "description": "Réservation via TravelEasy",
                        },
                        "unit_amount": int(payload.amount * 100),
                    },
                    "quantity": 1,
                }
            ],
            mode="payment",
            success_url="http://localhost:3000/#/trips?payment=success",
            cancel_url="http://localhost:3000/#/booking/" + payload.trip_id,
            metadata={"user_id": user_id, "trip_id": payload.trip_id},
        )
        return CheckoutSessionResponse(checkout_url=session.url)
    except stripe.error.StripeError as e:
        raise HTTPException(status_code=400, detail=str(e))


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
