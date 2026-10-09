from fastapi import APIRouter

router = APIRouter(tags=["Health"])

@router.get("/health")
def health_check():
    return {
        "success": True,
        "message": "MicroplastIA API funcionando correctamente",
        "data": {
            "status": "ok"
        }
    }