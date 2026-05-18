from typing import List, Optional
import json

from openai import AsyncOpenAI

from app.core.config import settings

client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)

SYSTEM_PROMPT = """
Tu es Ouicooly, un assistant expert en voyages. Tu aides les utilisateurs à planifier
leur voyage en tenant compte de leur budget, de leurs dates et de leurs préférences.
Tu proposes des options de transport (train, avion), d'hébergement et d'activités.
Tu réponds toujours en français de manière concise et enthousiaste.
"""


async def chat_with_assistant(
    messages: List[dict],
    trip_context: Optional[dict] = None,
) -> str:
    system_content = SYSTEM_PROMPT
    if trip_context:
        system_content += f"\n\nContexte du voyage en cours : {json.dumps(trip_context, ensure_ascii=False)}"

    response = await client.chat.completions.create(
        model=settings.OPENAI_MODEL,
        messages=[
            {"role": "system", "content": system_content},
            *messages,
        ],
        temperature=0.7,
        max_tokens=1024,
    )
    return response.choices[0].message.content


async def generate_trip_proposals(trip_id: str) -> None:
    """Génère des propositions IA pour un voyage (exécuté en background task)."""
    from app.core.database import AsyncSessionLocal
    from app.models.trip import Trip, TripStatus
    from sqlalchemy import select
    import uuid

    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Trip).where(Trip.id == uuid.UUID(trip_id)))
        trip = result.scalar_one_or_none()
        if not trip:
            return

        trip.status = TripStatus.SEARCHING
        await db.flush()

        prompt = (
            f"Génère 3 propositions de voyage de {trip.origin_city} vers {trip.destination_city} "
            f"du {trip.departure_date} "
            f"(budget : {trip.budget_min}€ – {trip.budget_max}€, {trip.num_travelers} voyageur(s)). "
            "Réponds en JSON structuré avec les champs : id, title, transport, hotel, total_price, highlights."
        )

        try:
            response = await client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": prompt},
                ],
                response_format={"type": "json_object"},
                temperature=0.8,
            )
            proposals = json.loads(response.choices[0].message.content)
            trip.ai_proposals = proposals
            trip.status = TripStatus.PROPOSED
        except Exception:
            trip.status = TripStatus.DRAFT

        await db.commit()
