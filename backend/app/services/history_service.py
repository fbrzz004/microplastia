from datetime import datetime
from typing import Optional, Sequence

from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.models.result import ResultadoAnalisis
from app.models.sample import Muestra
from app.schemas.analysis import AnalysisData, DetectionItem
from app.schemas.history import HistoryDetail, HistoryItem


def save_analysis(
    db: Session,
    result: AnalysisData,
    user_id: int,
    client_uuid: Optional[str] = None,
    is_offline_sync: bool = False,
) -> ResultadoAnalisis:

    if client_uuid:
        existente = get_existing_analysis(
            db=db,
            user_id=user_id,
            client_uuid=client_uuid,
        )

        if existente:
            return existente

    try:
        muestra = Muestra(
            id_usuario=user_id,
            descripcion=result.sample_id,
            estado="Analizada",
            imagen_url=None,
            client_uuid=client_uuid,
        )

        db.add(muestra)
        db.flush()

        registro = ResultadoAnalisis(
            id_muestra=muestra.id_muestra,
            total_particulas=result.total_particles,
            confianza_promedio=result.confidence,
            desglose=dict(result.breakdown),
            detecciones=[
                d.model_dump()
                for d in result.detections
            ],
            tiempo_procesamiento_ms=result.processing_time_ms,
            imagen_anotada_url=result.annotated_image_url,
            fecha_sincronizacion=(
                func.now() if is_offline_sync else None
            ),
        )

        db.add(registro)
        db.commit()
        db.refresh(registro)

        return registro

    except Exception:
        db.rollback()
        raise


def list_results(
    db: Session,
    user_id: int,
    query: Optional[str] = None,
    limit: int = 20,
    offset: int = 0,
) -> tuple[Sequence[ResultadoAnalisis], int]:

    consulta = (
        db.query(ResultadoAnalisis)
        .join(ResultadoAnalisis.muestra)
        .options(
            joinedload(ResultadoAnalisis.muestra)
        )
        .filter(
            Muestra.id_usuario == user_id
        )
    )

    if query:

        patron = f"%{query.strip()}%"

        consulta = consulta.filter(
            Muestra.descripcion.ilike(patron)
        )

    total = consulta.count()

    registros = (
        consulta
        .order_by(
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

    return (
        db.query(ResultadoAnalisis)
        .join(ResultadoAnalisis.muestra)
        .options(
            joinedload(ResultadoAnalisis.muestra)
        )
        .filter(
            ResultadoAnalisis.id_resultado == result_id,
            Muestra.id_usuario == user_id,
        )
        .first()
    )


def _created_at(
    registro: ResultadoAnalisis
) -> Optional[datetime]:

    return (
        registro.fecha_creacion
        or registro.muestra.fecha_registro
    )


def to_history_item(
    registro: ResultadoAnalisis
) -> HistoryItem:

    muestra = registro.muestra

    sample_id = (
        muestra.descripcion
        or f"MUESTRA-{muestra.id_muestra}"
    )

    return HistoryItem(
        id=registro.id_resultado,
        sample_id=sample_id,
        created_at=_created_at(registro),
        total_particles=registro.total_particulas,
        confidence=registro.confianza_promedio,
        annotated_image_url=registro.imagen_anotada_url,
    )


def to_history_detail(
    registro: ResultadoAnalisis
) -> HistoryDetail:

    detecciones = [
        DetectionItem.model_validate(deteccion)
        for deteccion in (
            registro.detecciones or []
        )
    ]

    return HistoryDetail(
        **to_history_item(registro).model_dump(),
        breakdown=registro.desglose or {},
        detections=detecciones,
        processing_time_ms=(
            registro.tiempo_procesamiento_ms
        ),
    )

def get_existing_analysis(
    db: Session,
    user_id: int,
    client_uuid: str,
) -> Optional[ResultadoAnalisis]:

    return (
        db.query(ResultadoAnalisis)
        .join(ResultadoAnalisis.muestra)
        .options(joinedload(ResultadoAnalisis.muestra))
        .filter(
            Muestra.id_usuario == user_id,
            Muestra.client_uuid == client_uuid,
        )
        .first()
    )

def to_analysis_data(
    registro: ResultadoAnalisis
) -> AnalysisData:

    muestra = registro.muestra

    detecciones = [
        DetectionItem.model_validate(d)
        for d in (registro.detecciones or [])
    ]

    return AnalysisData(
        result_id=registro.id_resultado,
        sample_id=(
            muestra.descripcion
            if muestra and muestra.descripcion
            else f"MUESTRA-{muestra.id_muestra}"
        ),
        total_particles=registro.total_particulas,
        confidence=registro.confianza_promedio,
        breakdown=registro.desglose or {},
        detections=detecciones,
        processing_time_ms=registro.tiempo_procesamiento_ms,
        annotated_image_url=registro.imagen_anotada_url,
    )