from fastapi import APIRouter

router = APIRouter(tags=["Analysis"])

@router.post("/analyze")
async def analyze_sample():
    # Mock temporal. Todavía no ejecuta YOLOv8n.
    return {
        "success": True,
        "message": "Respuesta simulada de análisis",
        "data": {
            "sample_id": "Muestra #024",
            "total_particles": 12,
            "confidence": 0.92,
            "breakdown": {
                "fiber": 6,
                "fragment": 4,
                "dirt": 2
            }
        }
    }