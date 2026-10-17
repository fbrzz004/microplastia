from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.v1.router import api_router
from app.core.config import settings
from app.db.session import Base, engine

# Crear tablas en base de datos al inicio
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    description=settings.description,
    version="1.0.0",
    debug=settings.debug,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Servir archivos estáticos generados
static_path = Path(__file__).resolve().parent.parent / settings.static_dir
static_path.mkdir(parents=True, exist_ok=True)
app.mount("/static", StaticFiles(directory=str(static_path)), name="static")

@app.get("/")
def read_root():
    return {
        "status": "success",
        "message": "MicroplastIA Backend funcionando correctamente"
    }

app.include_router(
    api_router,
    prefix=settings.api_v1_prefix,
)