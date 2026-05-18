from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import List

from app.core.security import get_current_user_id
from app.services.ai_service import chat_with_assistant

router = APIRouter()


class ChatMessage(BaseModel):
    role: str  # "user" | "assistant"
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    trip_context: dict | None = None


class ChatResponse(BaseModel):
    reply: str


@router.post("/chat", response_model=ChatResponse)
async def ai_chat(
    payload: ChatRequest,
    user_id: str = Depends(get_current_user_id),
):
    reply = await chat_with_assistant(
        messages=[m.model_dump() for m in payload.messages],
        trip_context=payload.trip_context,
    )
    return ChatResponse(reply=reply)
