from fastapi import APIRouter

from app.api.v1.endpoints import (
    health,
    analyze,
    auth,
    history,
    results,
    admin,
    users,
)

api_router = APIRouter()

api_router.include_router(health.router)
api_router.include_router(analyze.router)
api_router.include_router(auth.router)
api_router.include_router(history.router)
api_router.include_router(results.router)
api_router.include_router(admin.router)
api_router.include_router(users.router)
