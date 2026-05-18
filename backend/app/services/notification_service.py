from typing import Optional
import httpx


async def send_push_notification(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
    firebase_server_key: str = "",
) -> bool:
    """Envoie une notification push via Firebase Cloud Messaging."""
    if not fcm_token or not firebase_server_key:
        return False

    payload = {
        "to": fcm_token,
        "notification": {"title": title, "body": body},
        "data": data or {},
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://fcm.googleapis.com/fcm/send",
            json=payload,
            headers={
                "Authorization": f"key={firebase_server_key}",
                "Content-Type": "application/json",
            },
            timeout=10.0,
        )
        return response.status_code == 200
