from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.security import get_current_admin
from app.db.session import get_db

from app.models.user import Usuario
from app.models.sample import Muestra
from app.models.result import ResultadoAnalisis

from app.schemas.admin import (
    UsuarioAdminResponse,
    MuestraAdminResponse,
    DashboardAdminResponse,
)


router = APIRouter(
    prefix="/admin",
    tags=["Admin"]
)


# ==========================================
# CONFIGURACIÓN DEL MODELO MÓVIL
# ==========================================

MODELO_ACTIVO = "best.tflite"

MODELO_OPERATIVO = True

RESOLUCION_INFERENCIA = 320

UMBRAL_CONFIANZA = 0.25

CLASES_MODELO = {
    0: "partícula orgánica",
    1: "fibra",
    2: "fragmento",
    3: "gránulo",
}


# ==========================================
# DASHBOARD
# ==========================================

@router.get(
    "/dashboard",
    response_model=DashboardAdminResponse
)
def obtener_dashboard(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(get_current_admin)
):

    # --------------------------------------
    # USUARIOS MÓVILES
    # --------------------------------------

    usuarios_registrados = (
        db.query(
            func.count(Usuario.id_usuario)
        )
        .filter(
            Usuario.rol == "usuario"
        )
        .scalar()
    ) or 0


    # --------------------------------------
    # ANÁLISIS
    # --------------------------------------

    muestras_analizadas = (
        db.query(
            func.count(
                ResultadoAnalisis.id_resultado
            )
        )
        .scalar()
    ) or 0


    # --------------------------------------
    # PARTÍCULAS DETECTADAS
    # --------------------------------------

    particulas_detectadas = (
        db.query(
            func.coalesce(
                func.sum(
                    ResultadoAnalisis.total_particulas
                ),
                0
            )
        )
        .scalar()
    ) or 0


    # --------------------------------------
    # TIEMPO PROMEDIO DE INFERENCIA
    # --------------------------------------

    tiempo_promedio = (
        db.query(
            func.avg(
                ResultadoAnalisis.tiempo_procesamiento_ms
            )
        )
        .scalar()
    )

    tiempo_promedio_inferencia_ms = (
        round(float(tiempo_promedio), 2)
        if tiempo_promedio is not None
        else 0.0
    )


    # --------------------------------------
    # ÚLTIMA INFERENCIA
    # --------------------------------------

    ultimo_resultado = (
        db.query(ResultadoAnalisis)
        .order_by(
            ResultadoAnalisis.fecha_creacion.desc(),
            ResultadoAnalisis.id_resultado.desc()
        )
        .first()
    )

    ultima_inferencia_ms = (
        round(
            float(
                ultimo_resultado.tiempo_procesamiento_ms
            ),
            2
        )
        if (
            ultimo_resultado
            and ultimo_resultado.tiempo_procesamiento_ms
            is not None
        )
        else None
    )


    # --------------------------------------
    # DISTRIBUCIÓN ACUMULADA
    # --------------------------------------

    distribucion = {
        "fibra": 0,
        "fragmento": 0,
        "gránulo": 0,
        "película": 0,
    }

    resultados = (
        db.query(
            ResultadoAnalisis.desglose
        )
        .all()
    )

    for (desglose,) in resultados:

        if not desglose:
            continue

        for clase, cantidad in desglose.items():

            nombre = (
                str(clase)
                .strip()
                .lower()
            )

            cantidad_entera = int(
                cantidad
            )

            if nombre in distribucion:
                distribucion[nombre] += (
                    cantidad_entera
                )

            elif nombre == "granulo":
                distribucion["gránulo"] += (
                    cantidad_entera
                )

            elif nombre == "pelicula":
                distribucion["película"] += (
                    cantidad_entera
                )


    # --------------------------------------
    # MODELO DE IA
    # --------------------------------------
    #
    # La inferencia ya no se ejecuta
    # en FastAPI / Render.
    #
    # El modelo best.tflite se ejecuta
    # localmente en Flutter / Android.
    # --------------------------------------

    modelo_activo = MODELO_ACTIVO

    modelo_operativo = (
        MODELO_OPERATIVO
    )

    numero_clases = len(
        CLASES_MODELO
    )


    # --------------------------------------
    # RESPUESTA
    # --------------------------------------

    return DashboardAdminResponse(
        muestras_analizadas=(
            muestras_analizadas
        ),

        particulas_detectadas=(
            particulas_detectadas
        ),

        usuarios_registrados=(
            usuarios_registrados
        ),

        modelo_activo=(
            modelo_activo
        ),

        modelo_operativo=(
            modelo_operativo
        ),

        resolucion_inferencia=(
            RESOLUCION_INFERENCIA
        ),

        umbral_confianza=(
            UMBRAL_CONFIANZA
        ),

        numero_clases=(
            numero_clases
        ),

        tiempo_promedio_inferencia_ms=(
            tiempo_promedio_inferencia_ms
        ),

        ultima_inferencia_ms=(
            ultima_inferencia_ms
        ),

        distribucion=(
            distribucion
        )
    )


# ==========================================
# USUARIOS DE LA APLICACIÓN MÓVIL
# ==========================================

@router.get(
    "/usuarios",
    response_model=list[UsuarioAdminResponse]
)
def listar_usuarios(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(get_current_admin)
):

    usuarios = (
        db.query(Usuario)
        .filter(
            Usuario.rol == "usuario"
        )
        .order_by(
            Usuario.id_usuario.asc()
        )
        .all()
    )

    respuesta = []

    for usuario in usuarios:

        muestras_realizadas = (
            db.query(
                func.count(
                    Muestra.id_muestra
                )
            )
            .filter(
                Muestra.id_usuario
                == usuario.id_usuario
            )
            .scalar()
        ) or 0

        ultimo_analisis = (
            db.query(
                func.max(
                    ResultadoAnalisis.fecha_creacion
                )
            )
            .join(
                Muestra,
                ResultadoAnalisis.id_muestra
                == Muestra.id_muestra
            )
            .filter(
                Muestra.id_usuario
                == usuario.id_usuario
            )
            .scalar()
        )

        respuesta.append(
            UsuarioAdminResponse(
                id_usuario=(
                    usuario.id_usuario
                ),

                nombre=(
                    usuario.nombre
                ),

                apellido=(
                    usuario.apellido
                ),

                correo=(
                    usuario.correo
                ),

                rol=(
                    usuario.rol
                ),

                estado=(
                    usuario.estado
                ),

                muestras_realizadas=(
                    muestras_realizadas
                ),

                ultimo_analisis=(
                    ultimo_analisis
                )
            )
        )

    return respuesta


# ==========================================
# MUESTRAS
# ==========================================

@router.get(
    "/muestras",
    response_model=list[MuestraAdminResponse]
)
def listar_muestras(
    db: Session = Depends(get_db),
    admin: Usuario = Depends(get_current_admin)
):

    registros = (
        db.query(
            Muestra,
            ResultadoAnalisis,
            Usuario
        )
        .join(
            Usuario,
            Muestra.id_usuario
            == Usuario.id_usuario
        )
        .outerjoin(
            ResultadoAnalisis,
            ResultadoAnalisis.id_muestra
            == Muestra.id_muestra
        )
        .filter(
            Usuario.rol == "usuario"
        )
        .order_by(
            Muestra.fecha_registro.desc()
        )
        .all()
    )

    respuesta = []

    for (
        muestra,
        resultado,
        usuario
    ) in registros:

        nombre_usuario = (
            usuario.nombre
        )

        if usuario.apellido:
            nombre_usuario += (
                f" {usuario.apellido}"
            )

        codigo_muestra = (
            muestra.descripcion
            if muestra.descripcion
            else (
                f"MUESTRA-"
                f"{muestra.id_muestra}"
            )
        )

        fecha = (
            resultado.fecha_creacion
            if resultado
            else muestra.fecha_registro
        )

        respuesta.append(
            MuestraAdminResponse(
                id_muestra=(
                    muestra.id_muestra
                ),

                codigo=(
                    codigo_muestra
                ),

                usuario=(
                    nombre_usuario
                ),

                correo=(
                    usuario.correo
                ),

                fecha=(
                    fecha
                ),

                total_particulas=(
                    resultado.total_particulas
                    if resultado
                    else 0
                ),

                confianza_promedio=(
                    resultado.confianza_promedio
                    if resultado
                    else 0.0
                ),

                estado=(
                    muestra.estado
                    if muestra.estado
                    else (
                        "Analizada"
                        if resultado
                        else "Pendiente"
                    )
                )
            )
        )

    return respuesta