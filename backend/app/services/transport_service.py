from typing import List
import httpx

from app.core.config import settings


async def search_transports(origin: str, destination: str, date: str) -> List[dict]:
    """Recherche les transports disponibles (SNCF + Amadeus)."""
    results = []

    # SNCF trains
    try:
        trains = await _search_sncf(origin, destination, date)
        results.extend(trains)
    except Exception:
        pass

    # Amadeus flights
    try:
        flights = await _search_amadeus(origin, destination, date)
        results.extend(flights)
    except Exception:
        pass

    return sorted(results, key=lambda x: x.get("price", 9999))


async def _search_sncf(origin: str, destination: str, date: str) -> List[dict]:
    if not settings.SNCF_API_KEY:
        return []

    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{settings.SNCF_API_BASE_URL}/journeys",
            params={"from": origin, "to": destination, "datetime": date},
            auth=(settings.SNCF_API_KEY, ""),
            timeout=10.0,
        )
        if response.status_code != 200:
            return []

        data = response.json()
        journeys = data.get("journeys", [])
        return [
            {
                "type": "train",
                "provider": "sncf",
                "origin": origin,
                "destination": destination,
                "departure": j.get("departure_date_time"),
                "arrival": j.get("arrival_date_time"),
                "duration": j.get("duration"),
                "price": j.get("fare", {}).get("total", {}).get("value"),
                "raw": j,
            }
            for j in journeys[:5]
        ]


async def _search_amadeus(origin: str, destination: str, date: str) -> List[dict]:
    if not settings.AMADEUS_API_KEY:
        return []

    # Obtenir le token OAuth2
    async with httpx.AsyncClient() as client:
        token_resp = await client.post(
            f"{settings.AMADEUS_BASE_URL}/v1/security/oauth2/token",
            data={
                "grant_type": "client_credentials",
                "client_id": settings.AMADEUS_API_KEY,
                "client_secret": settings.AMADEUS_API_SECRET,
            },
        )
        if token_resp.status_code != 200:
            return []

        token = token_resp.json()["access_token"]

        offers_resp = await client.get(
            f"{settings.AMADEUS_BASE_URL}/v2/shopping/flight-offers",
            params={
                "originLocationCode": origin[:3].upper(),
                "destinationLocationCode": destination[:3].upper(),
                "departureDate": date,
                "adults": 1,
                "max": 5,
            },
            headers={"Authorization": f"Bearer {token}"},
            timeout=15.0,
        )
        if offers_resp.status_code != 200:
            return []

        offers = offers_resp.json().get("data", [])
        return [
            {
                "type": "flight",
                "provider": "amadeus",
                "price": float(o["price"]["total"]),
                "currency": o["price"]["currency"],
                "raw": o,
            }
            for o in offers
        ]
