from datetime import datetime
from typing import Optional, Sequence

from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.models.result import ResultadoAnalisis
from app.models.sample import Muestra
from app.schemas.analysis import AnalysisData, DetectionItem
from app.schemas.history import HistoryDetail, HistoryItem


def save_analysis(
    db: Session,
    result: AnalysisData,
    filename: Optional[str],
    user_id: Optional[int],
) -> ResultadoAnalisis:
    """Guarda la muestra y su resultado de inferencia."""

    muestra = Muestra(
        codigo=result.sample_id,
        nombre_archivo=filename,
        id_usuario=user_id,
    )
    db.add(muestra)
    db.flush()

    registro = ResultadoAnalisis(
        id_muestra=muestra.id_muestra,
        total_particulas=result.total_particles,
        confianza_promedio=result.confidence,
        desglose=dict(result.breakdown),
        detecciones=[d.model_dump() for d in result.detections],
        tiempo_procesamiento_ms=result.processing_time_ms,
        imagen_anotada_url=result.annotated_image_url,
    )
    db.add(registro)
    db.commit()
    db.refresh(registro)

    return registro


def list_results(
    db: Session,
    user_id: int,
    query: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
) -> tuple[Sequence[ResultadoAnalisis], int]:
    """Lista los análisis del usuario, del más reciente al más antiguo."""

    consulta = (
        db.query(ResultadoAnalisis)
        .join(ResultadoAnalisis.muestra)
        .options(joinedload(ResultadoAnalisis.muestra))
        .filter(Muestra.id_usuario == user_id)
    )

    if query:
        patron = f"%{query.strip()}%"
        consulta = consulta.filter(
            or_(
                Muestra.codigo.ilike(patron),
                Muestra.nombre_archivo.ilike(patron),
            )
        )

    total = consulta.count()
    registros = (
        consulta.order_by(
            ResultadoAnalisis.fecha_creacion.desc(),
            ResultadoAnalisis.id_resultado.desc(),
        )
        .offset(offset)
        .limit(limit)
        .all()
    )

    return registros, total


def get_result(
    db: Session,
    result_id: int,
    user_id: int,
) -> Optional[ResultadoAnalisis]:
    """Devuelve un análisis solo si pertenece al usuario indicado."""

    return (
        db.query(ResultadoAnalisis)
        .join(ResultadoAnalisis.muestra)
        .options(joinedload(ResultadoAnalisis.muestra))
        .filter(
            ResultadoAnalisis.id_resultado == result_id,
            Muestra.id_usuario == user_id,
        )
        .first()
    )


def _created_at(registro: ResultadoAnalisis) -> datetime:
    fecha = registro.fecha_creacion or registro.muestra.fecha_creacion
    return fecha


def to_history_item(registro: ResultadoAnalisis) -> HistoryItem:
    muestra = registro.muestra

    return HistoryItem(
        id=registro.id_resultado,
        sample_id=muestra.codigo,
        filename=muestra.nombre_archivo,
        created_at=_created_at(registro),
        total_particles=registro.total_particulas,
        confidence=registro.confianza_promedio,
        annotated_image_url=registro.imagen_anotada_url,
    )


def to_history_detail(registro: ResultadoAnalisis) -> HistoryDetail:
    detecciones = [
        DetectionItem.model_validate(deteccion)
        for deteccion in (registro.detecciones or [])
    ]

    return HistoryDetail(
        **to_history_item(registro).model_dump(),
        breakdown=registro.desglose or {},
        detections=detecciones,
        processing_time_ms=registro.tiempo_procesamiento_ms,
    )
