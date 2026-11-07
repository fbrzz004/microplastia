from fastapi import APIRouter, Depends
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.security import get_current_admin
from app.db.session import get_db

from app.models.user import Usuario
from app.models.sample import Muestra
from app.models.result import ResultadoAnalisis
from app.models.model_ai import ModeloIA

from app.schemas.admin import (
    UsuarioAdminResponse,
    MuestraAdminResponse,
    DashboardAdminResponse,
)
from app.services.notification_service import (
    create_system_notifications_for_admins,
)


router = APIRouter(
    prefix="/admin",
    tags=["Admin"]
)


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
        round(
            float(tiempo_promedio),
            2
        )
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
    # MODELO DE IA ACTIVO
    # --------------------------------------

    modelo = (
        db.query(ModeloIA)
        .filter(
            ModeloIA.estado.is_(True)
        )
        .order_by(
            ModeloIA.fecha_publicacion.desc(),
            ModeloIA.id_modelo.desc(),
        )
        .first()
    )

    if modelo is not None:

        modelo_activo = (
            f"{modelo.nombre} v{modelo.version}"
        )

        modelo_operativo = True

        resolucion_inferencia = (
            modelo.input_size
            if modelo.input_size is not None
            else 320
        )

        umbral_confianza = (
            float(
                modelo.confidence_threshold
            )
            if (
                modelo.confidence_threshold
                is not None
            )
            else 0.25
        )

        numero_clases = (
            len(modelo.clases)
            if modelo.clases
            else 0
        )

    else:

        modelo_activo = "Sin modelo activo"

        modelo_operativo = False

        resolucion_inferencia = 0

        umbral_confianza = 0.0

        numero_clases = 0


    # --------------------------------------
    # USO DE MODELOS
    # ÚLTIMOS 50 ANÁLISIS
    # --------------------------------------

    analisis_modelo = (
        db.query(ResultadoAnalisis)
        .filter(
            ResultadoAnalisis.modelo_version.isnot(None)
        )
        .order_by(
            ResultadoAnalisis.fecha_creacion.desc(),
            ResultadoAnalisis.id_resultado.desc()
        )
        .limit(50)
        .all()
    )

    analisis_con_modelo = len(
        analisis_modelo
    )

    uso_downloaded = sum(
        1
        for resultado in analisis_modelo
        if resultado.modelo_origen == "downloaded"
    )

    uso_fallback = sum(
        1
        for resultado in analisis_modelo
        if resultado.modelo_origen == "fallback"
    )


    # --------------------------------------
    # PORCENTAJES DE USO
    # --------------------------------------

    if analisis_con_modelo > 0:

        porcentaje_downloaded = round(
            (
                uso_downloaded
                / analisis_con_modelo
            ) * 100,
            2
        )

        porcentaje_fallback = round(
            (
                uso_fallback
                / analisis_con_modelo
            ) * 100,
            2
        )

    else:

        porcentaje_downloaded = 0.0
        porcentaje_fallback = 0.0


    # --------------------------------------
    # ALERTA INTELIGENTE DE FALLBACK
    # --------------------------------------

    fallback_version_antigua = False

    if modelo is not None:

        fallback_version_antigua = any(
            resultado.modelo_origen == "fallback"
            and resultado.modelo_version is not None
            and resultado.modelo_version != modelo.version
            for resultado in analisis_modelo
        )

    alerta_fallback = (
        porcentaje_fallback > 20
        and fallback_version_antigua
    )


    # --------------------------------------
    # NOTIFICACIONES DE SISTEMA
    # --------------------------------------

    if not modelo_operativo:
        create_system_notifications_for_admins(
            db,
            tipo="model",
            titulo="Modelo de IA no disponible",
            mensaje=(
                f"El modelo {modelo_activo} "
                "no está operativo. Revisa el estado "
                "del servicio."
            ),
        )

    if alerta_fallback:
        create_system_notifications_for_admins(
            db,
            tipo="model",
            titulo="Uso elevado del modelo local",
            mensaje=(
                f"{porcentaje_fallback}% de los análisis "
                "usó el modelo local. Revisa la "
                "sincronización del modelo TFLite."
            ),
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
            resolucion_inferencia
        ),

        umbral_confianza=(
            umbral_confianza
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
        ),

        analisis_con_modelo=(
            analisis_con_modelo
        ),

        uso_downloaded=(
            uso_downloaded
        ),

        uso_fallback=(
            uso_fallback
        ),

        porcentaje_downloaded=(
            porcentaje_downloaded
        ),

        porcentaje_fallback=(
            porcentaje_fallback
        ),

        alerta_fallback=(
            alerta_fallback
        )
    )


# ==========================================
# USUARIOS DE LA APLICACIÓN MÓVIL
# OPTIMIZADO: UNA CONSULTA
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
        db.query(
            Usuario.id_usuario,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.correo,
            Usuario.rol,
            Usuario.estado,

            func.count(
                func.distinct(
                    Muestra.id_muestra
                )
            ).label(
                "muestras_realizadas"
            ),

            func.max(
                ResultadoAnalisis.fecha_creacion
            ).label(
                "ultimo_analisis"
            )
        )

        .outerjoin(
            Muestra,
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

        .group_by(
            Usuario.id_usuario,
            Usuario.nombre,
            Usuario.apellido,
            Usuario.correo,
            Usuario.rol,
            Usuario.estado
        )

        .order_by(
            Usuario.id_usuario.asc()
        )

        .all()
    )

    return [
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
                usuario.muestras_realizadas
                or 0
            ),

            ultimo_analisis=(
                usuario.ultimo_analisis
            )
        )

        for usuario in usuarios
    ]


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

                modelo_nombre=(
                    resultado.modelo_nombre
                    if resultado
                    else None
                ),

                modelo_version=(
                    resultado.modelo_version
                    if resultado
                    else None
                ),

                modelo_origen=(
                    resultado.modelo_origen
                    if resultado
                    else None
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