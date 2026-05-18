import stripe
from app.core.config import settings

stripe.api_key = settings.STRIPE_SECRET_KEY


async def create_or_get_customer(email: str, name: str) -> str:
    customers = stripe.Customer.list(email=email, limit=1)
    if customers.data:
        return customers.data[0].id

    customer = stripe.Customer.create(email=email, name=name)
    return customer.id


async def refund_payment_intent(payment_intent_id: str) -> bool:
    try:
        stripe.Refund.create(payment_intent=payment_intent_id)
        return True
    except stripe.StripeError:
        return False
