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

    modelo_nombre: str | None = None
    modelo_version: str | None = None
    modelo_origen: str | None = None


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

    # Uso del modelo en los últimos 50 análisis
    analisis_con_modelo: int
    uso_downloaded: int
    uso_fallback: int

    porcentaje_downloaded: float
    porcentaje_fallback: float

    # Solo se activa cuando existe un problema real
    # con una versión fallback antigua.
    alerta_fallback: bool