import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.mark.asyncio
async def test_register_and_login(monkeypatch):
    # Ces tests nécessitent une base de données de test configurée
    # Lancer avec : DATABASE_URL=postgresql+asyncpg://... pytest
    pass
