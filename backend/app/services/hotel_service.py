from typing import List
import httpx

from app.core.config import settings


async def search_hotels(
    destination: str,
    check_in: str,
    check_out: str,
    budget_max: float,
) -> List[dict]:
    """Recherche les hôtels disponibles via Booking.com Rapid API."""
    if not settings.BOOKING_API_KEY:
        return []

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.BOOKING_API_BASE_URL}/properties/list",
            params={
                "dest_type": "city",
                "dest_id": destination,
                "checkin_date": check_in,
                "checkout_date": check_out,
                "price_max": int(budget_max),
                "room_number": 1,
                "adults_number": 1,
                "order_by": "price",
                "page_number": 0,
                "units": "metric",
                "filter_by_currency": "EUR",
            },
            headers={
                "x-rapidapi-key": settings.BOOKING_API_KEY,
                "x-rapidapi-host": "booking-com.p.rapidapi.com",
            },
            timeout=15.0,
        )

        if response.status_code != 200:
            return []

        results = response.json().get("result", [])
        return [
            {
                "type": "hotel",
                "provider": "booking",
                "name": h.get("hotel_name"),
                "stars": h.get("class"),
                "price_per_night": h.get("min_total_price"),
                "address": h.get("address"),
                "review_score": h.get("review_score"),
                "url": h.get("url"),
                "raw": h,
            }
            for h in results[:10]
        ]
