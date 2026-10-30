import gc
import logging
import time
import uuid
from pathlib import Path
from typing import Dict, List, Optional

import cv2

from ultralytics import YOLO

from app.core.config import settings
from app.core.file_validation import (
    decode_and_validate_image,
)
from app.schemas.analysis import (
    AnalysisData,
    DetectionItem,
)
from app.services.storage_service import (
    storage_service,
)


logger = logging.getLogger("microplastia")


# ==========================================================
# MAPEO DE CLASES
# ==========================================================

MAPEO_CLASES = {
    "dirt": "partícula orgánica",
    "fiber": "fibra",
    "fibra": "fibra",
    "fragment": "fragmento",
    "fragmento": "fragmento",
    "pellet": "gránulo",
    "granulo": "gránulo",
    "gránulo": "gránulo",
    "film": "película",
    "pelicula": "película",
    "película": "película",
}


def _clasificar(nombre_crudo: str) -> str:
    nombre = (
        nombre_crudo
        or ""
    ).strip().lower()

    for clave, categoria in MAPEO_CLASES.items():
        if clave in nombre:
            return categoria

    return (
        nombre_crudo
        or "desconocida"
    )


# ==========================================================
# INFERENCIA
# ==========================================================

class InferenceService:

    def __init__(self):
        self.model: Optional[YOLO] = None

        self.model_path = (
            self._resolve_model_path()
        )

        self._load_model()


    # ------------------------------------------------------
    # RESOLVER RUTA DEL MODELO
    # ------------------------------------------------------

    def _resolve_model_path(self) -> Path:
        base_dir = (
            Path(__file__)
            .resolve()
            .parent
            .parent
            .parent
        )

        possible_paths = [
            Path(settings.model_path),

            base_dir
            / settings.model_path,

            base_dir
            / "weights"
            / "best.pt",

            base_dir
            / "app"
            / "weights"
            / "best.pt",
        ]

        for path in possible_paths:
            if (
                path.exists()
                and path.is_file()
            ):
                return path

        return (
            base_dir
            / "weights"
            / "best.pt"
        )


    # ------------------------------------------------------
    # CARGAR MODELO UNA SOLA VEZ
    # ------------------------------------------------------

    def _load_model(self) -> None:
        if not self.model_path.exists():
            raise RuntimeError(
                "No se encontró el modelo "
                "de inferencia configurado."
            )

        self.model = YOLO(
            str(self.model_path)
        )


    # ------------------------------------------------------
    # REDUCIR IMAGEN PARA INFERENCIA
    # ------------------------------------------------------

    @staticmethod
    def _resize_for_inference(
        image,
        max_dimension: int = settings.inference_max_dimension,
    ):
        """
        Reduce imágenes muy grandes antes de enviarlas
        al modelo para disminuir consumo de RAM.

        No amplía imágenes pequeñas.
        """

        height, width = image.shape[:2]

        largest_dimension = max(
            width,
            height,
        )

        if largest_dimension <= max_dimension:
            return image

        scale = (
            max_dimension
            / largest_dimension
        )

        new_width = max(
            1,
            int(width * scale),
        )

        new_height = max(
            1,
            int(height * scale),
        )

        return cv2.resize(
            image,
            (
                new_width,
                new_height,
            ),
            interpolation=cv2.INTER_AREA,
        )


    # ------------------------------------------------------
    # PREDICCIÓN
    # ------------------------------------------------------

    def predict(
        self,
        image_bytes: bytes,
        original_filename: str = "sample.jpg",
        sample_id: Optional[str] = None,
    ) -> AnalysisData:

        start_time = time.perf_counter()
        stage_time = start_time

        if self.model is None:
            raise RuntimeError(
                "El modelo de inferencia "
                "no está cargado."
            )


        # --------------------------------------------------
        # SAMPLE ID
        # --------------------------------------------------

        if not sample_id:
            sample_id = (
                "MUESTRA-"
                f"{uuid.uuid4().hex[:8].upper()}"
            )


        # --------------------------------------------------
        # VALIDACIÓN REAL
        # --------------------------------------------------

        img_bgr = (
            decode_and_validate_image(
                image_bytes
            )
        )

        validation_ms = round(
            (time.perf_counter() - stage_time) * 1000,
            2,
        )
        stage_time = time.perf_counter()

        # Los bytes originales ya no son necesarios.
        del image_bytes


        # --------------------------------------------------
        # GUARDAR ORIGINAL
        # --------------------------------------------------

        original_image_url = (
            storage_service
            .save_original_image(
                img_bgr
            )
        )

        original_storage_ms = round(
            (time.perf_counter() - stage_time) * 1000,
            2,
        )
        stage_time = time.perf_counter()


        # --------------------------------------------------
        # REDUCIR IMAGEN PARA YOLO
        # --------------------------------------------------

        inference_image = (
            self._resize_for_inference(
                img_bgr,
                max_dimension=settings.inference_max_dimension,
            )
        )

        # Si resize generó otra imagen,
        # podemos liberar la original.
        if inference_image is not img_bgr:
            del img_bgr
            gc.collect()

        img_bgr = inference_image


        # --------------------------------------------------
        # INFERENCIA OPTIMIZADA
        # --------------------------------------------------

        results = self.model.predict(
            source=img_bgr,
            conf=settings.confidence_threshold,

            # 320 reduce trabajo de CPU y RAM en Render.
            imgsz=settings.inference_imgsz,

            # Render no tiene GPU.
            device="cpu",

            verbose=False,

            # Solo necesitamos una imagen.
            stream=False,
        )


        yolo_ms = round(
            (time.perf_counter() - stage_time) * 1000,
            2,
        )
        stage_time = time.perf_counter()

        result = results[0]

        boxes = result.boxes


        detections: List[
            DetectionItem
        ] = []

        breakdown: Dict[
            str,
            int
        ] = {}

        confidences: List[
            float
        ] = []


        names = (
            self.model.names
            if hasattr(
                self.model,
                "names"
            )
            else {}
        )


        # --------------------------------------------------
        # DETECCIONES
        # --------------------------------------------------

        if (
            boxes is not None
            and len(boxes) > 0
        ):

            for box in boxes:

                coords = [
                    round(
                        float(c),
                        2,
                    )
                    for c
                    in box.xyxy[0].tolist()
                ]

                confidence = round(
                    float(
                        box.conf[0].item()
                    ),
                    4,
                )

                class_id = int(
                    box.cls[0].item()
                )

                raw_name = names.get(
                    class_id,
                    "",
                )

                class_name = (
                    _clasificar(
                        raw_name
                    )
                )


                detections.append(
                    DetectionItem(
                        class_id=class_id,
                        class_name=class_name,
                        confidence=confidence,
                        box=coords,
                    )
                )


                breakdown[
                    class_name
                ] = (
                    breakdown.get(
                        class_name,
                        0,
                    )
                    + 1
                )


                confidences.append(
                    confidence
                )


                # ------------------------------------------
                # DIBUJAR DETECCIÓN
                # ------------------------------------------

                x1, y1, x2, y2 = [
                    int(c)
                    for c
                    in coords
                ]


                color = (
                    (0, 165, 255)
                    if class_name == "fibra"
                    else (0, 255, 0)
                )


                cv2.rectangle(
                    img_bgr,
                    (x1, y1),
                    (x2, y2),
                    color,
                    2,
                )


                cv2.putText(
                    img_bgr,
                    (
                        f"{class_name} "
                        f"{confidence:.2f}"
                    ),
                    (
                        x1,
                        max(
                            15,
                            y1 - 8,
                        ),
                    ),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.5,
                    color,
                    2,
                )


        # --------------------------------------------------
        # RESULTADOS
        # --------------------------------------------------

        total_particles = len(
            detections
        )


        avg_confidence = (
            round(
                sum(confidences)
                / len(confidences),
                4,
            )
            if confidences
            else 0.0
        )


        # --------------------------------------------------
        # LIBERAR OBJETOS DE YOLO
        # --------------------------------------------------

        del boxes
        del result
        del results

        gc.collect()


        # --------------------------------------------------
        # GUARDAR IMAGEN ANOTADA
        # --------------------------------------------------

        drawing_ms = round(
            (time.perf_counter() - stage_time) * 1000,
            2,
        )
        stage_time = time.perf_counter()

        annotated_image_url = (
            storage_service
            .save_annotated_image(
                img_bgr
            )
        )

        annotated_storage_ms = round(
            (time.perf_counter() - stage_time) * 1000,
            2,
        )


        # Ya no necesitamos la imagen.
        del img_bgr
        del inference_image

        gc.collect()


        # --------------------------------------------------
        # TIEMPO
        # --------------------------------------------------

        elapsed_ms = round(
            (
                time.perf_counter()
                - start_time
            )
            * 1000,
            2,
        )

        logger.info(
            "Analysis timing | sample_id=%s | validation_ms=%s | "
            "original_storage_ms=%s | yolo_ms=%s | drawing_ms=%s | "
            "annotated_storage_ms=%s | total_ms=%s | imgsz=%s | "
            "max_dimension=%s",
            sample_id,
            validation_ms,
            original_storage_ms,
            yolo_ms,
            drawing_ms,
            annotated_storage_ms,
            elapsed_ms,
            settings.inference_imgsz,
            settings.inference_max_dimension,
        )


        # --------------------------------------------------
        # RESPUESTA
        # --------------------------------------------------

        return AnalysisData(
            sample_id=sample_id,

            total_particles=(
                total_particles
            ),

            confidence=(
                avg_confidence
            ),

            breakdown=breakdown,

            detections=detections,

            processing_time_ms=(
                elapsed_ms
            ),

            original_image_url=(
                original_image_url
            ),

            annotated_image_url=(
                annotated_image_url
            ),
        )


# ==========================================================
# INSTANCIA GLOBAL
# ==========================================================

# Se carga una sola vez al iniciar FastAPI.
# No se crea un modelo nuevo por cada petición.
inference_service = InferenceService()