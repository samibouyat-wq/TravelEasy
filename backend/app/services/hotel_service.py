from typing import List
import httpx

from app.core.config import settings


async def search_hotels(
    destination: str,
    check_in: str,
    check_out: str,
    budget_max: float,
) -> List[dict]:
    if not settings.BOOKING_API_KEY:
        return []

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"https://{settings.BOOKING_API_HOST}/api/v1/hotels/searchHotels",
            params={
                "dest_id": destination,
                "search_type": "city",
                "arrival_date": check_in,
                "departure_date": check_out,
                "adults": "1",
                "room_qty": "1",
                "price_max": int(budget_max),
                "currency_code": "EUR",
                "languagecode": "fr",
            },
            headers={
                "x-rapidapi-key": settings.BOOKING_API_KEY,
                "x-rapidapi-host": settings.BOOKING_API_HOST,
            },
            timeout=15.0,
        )

        if response.status_code != 200:
            return []

        results = response.json().get("data", {}).get("hotels", [])
        return [
            {
                "type": "hotel",
                "provider": "booking",
                "name": h.get("property", {}).get("name"),
                "price_per_night": h.get("property", {}).get("priceBreakdown", {}).get("grossPrice", {}).get("value"),
                "review_score": h.get("property", {}).get("reviewScore"),
                "raw": h,
            }
            for h in results[:10]
        ]
