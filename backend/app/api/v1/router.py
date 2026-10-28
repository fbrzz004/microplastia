from fastapi import APIRouter

from app.api.v1.endpoints import (
    health,
    analyze,
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
    auth
=======
>>>>>>> Stashed changes
    auth,
    history,
    results,
    admin,
<<<<<<< Updated upstream
=======
    users,
>>>>>>> Stashed changes
>>>>>>> Stashed changes
)


api_router = APIRouter()


api_router.include_router(health.router)

api_router.include_router(analyze.router)
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
api_router.include_router(auth.router)
=======
>>>>>>> Stashed changes

api_router.include_router(auth.router)

api_router.include_router(history.router)

api_router.include_router(results.router)

<<<<<<< Updated upstream
api_router.include_router(admin.router)
=======
api_router.include_router(admin.router)

api_router.include_router(users.router)
>>>>>>> Stashed changes
>>>>>>> Stashed changes
