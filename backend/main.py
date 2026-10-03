from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="MicroplastIA API",
    description="Backend MVP para detección de microplásticos mediante IA",
    version="1.0.0"
)

# Permitir conexiones desde la app móvil o web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"status": "success", "message": "MicroplastIA Backend funcionando correctamente 🚀"}

@app.post("/api/v1/analyze")
async def analyze_sample():
    # Mock temporal de respuesta del modelo para el MVP
    return {
        "sample_id": "Muestra #024",
        "total_particles": 12,
        "confidence": 0.92,
        "breakdown": {
            "fibers": 6,
            "fragments": 4,
            "others": 2
        },
        "xai_explanation": "El modelo se enfocó principalmente en bordes, textura y forma de las partículas."
    }
