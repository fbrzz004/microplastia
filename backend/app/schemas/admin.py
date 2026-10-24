from datetime import datetime

from pydantic import BaseModel, EmailStr


class UsuarioAdminResponse(BaseModel):
    id_usuario: int
    nombre: str
    apellido: str | None = None
    correo: EmailStr
    rol: str
    estado: bool

    muestras_realizadas: int
    ultimo_analisis: datetime | None = None


class MuestraAdminResponse(BaseModel):
    id_muestra: int
    codigo: str
    usuario: str
    correo: EmailStr
    fecha: datetime
    total_particulas: int
    confianza_promedio: float
    estado: str


class DashboardAdminResponse(BaseModel):
    muestras_analizadas: int
    particulas_detectadas: int
    usuarios_registrados: int

    modelo_activo: str
    modelo_operativo: bool

    resolucion_inferencia: int
    umbral_confianza: float
    numero_clases: int

    tiempo_promedio_inferencia_ms: float
    ultima_inferencia_ms: float | None = None

    distribucion: dict[str, int]