import time
import uuid
from pathlib import Path
from typing import Dict, List, Optional
import cv2
import numpy as np

from ultralytics import YOLO
from app.core.config import settings
from app.schemas.analysis import AnalysisData, DetectionItem

# Clases reales del dataset (Roboflow v6, University of Alabama) y su
# equivalencia con las categorías morfológicas que muestra la app.
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
    """Traduce el nombre de clase del modelo a la categoría morfológica."""
    nombre = (nombre_crudo or "").strip().lower()
    for clave, categoria in MAPEO_CLASES.items():
        if clave in nombre:
            return categoria
    return nombre_crudo or "desconocida"


class InvalidImageError(ValueError):
    """La carga recibida no es una imagen decodificable."""


class InferenceService:
    def __init__(self):
        self.model: Optional[YOLO] = None
        self.model_path = self._resolve_model_path()
        self._load_model()
        self._ensure_directories()

    def _resolve_model_path(self) -> Path:
        base_dir = Path(__file__).resolve().parent.parent.parent
        possible_paths = [
            Path(settings.model_path),
            base_dir / settings.model_path,
            base_dir / "weights" / "best.pt",
            base_dir / "app" / "weights" / "best.pt",
            base_dir / "yolov8n.pt",
        ]
        for p in possible_paths:
            if p.exists() and p.is_file():
                return p
        return base_dir / "weights" / "best.pt"

    def _load_model(self):
        try:
            if self.model_path.exists():
                self.model = YOLO(str(self.model_path))
            else:
                self.model = YOLO("yolov8n.pt")
        except Exception:
            self.model = YOLO("yolov8n.pt")

    def _ensure_directories(self):
        base_dir = Path(__file__).resolve().parent.parent.parent
        self.upload_dir = base_dir / settings.upload_dir
        self.static_dir = base_dir / settings.static_dir / "detections"
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        self.static_dir.mkdir(parents=True, exist_ok=True)

    def predict(
        self,
        image_bytes: bytes,
        original_filename: str = "sample.jpg",
        sample_id: Optional[str] = None
    ) -> AnalysisData:
        start_time = time.perf_counter()

        if not sample_id:
            sample_id = f"MUESTRA-{uuid.uuid4().hex[:8].upper()}"

        # Validar que la carga sea una imagen decodificable antes de guardarla.
        nparr = np.frombuffer(image_bytes, np.uint8)
        img_bgr = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img_bgr is None:
            raise InvalidImageError(
                "El archivo recibido no es una imagen válida (JPG o PNG)."
            )

        file_id = f"{sample_id}_{int(time.time())}"
        raw_image_path = self.upload_dir / f"{file_id}.jpg"

        with open(raw_image_path, "wb") as f:
            f.write(image_bytes)

        # Inferencia con YOLOv8n
        results = self.model.predict(
            source=str(raw_image_path),
            conf=settings.confidence_threshold,
            imgsz=640,
            verbose=False,
        )

        result = results[0]
        boxes = result.boxes

        detections: List[DetectionItem] = []
        breakdown: Dict[str, int] = {}
        confidences: List[float] = []

        names = self.model.names if hasattr(self.model, "names") else {}

        if boxes is not None and len(boxes) > 0:
            for box in boxes:
                coords = [round(float(c), 2) for c in box.xyxy[0].tolist()]
                conf = round(float(box.conf[0].item()), 4)
                cls_id = int(box.cls[0].item())
                raw_name = names.get(cls_id, "")

                cls_name = _clasificar(raw_name)

                detections.append(
                    DetectionItem(
                        class_id=cls_id,
                        class_name=cls_name,
                        confidence=conf,
                        box=coords,
                    )
                )
                breakdown[cls_name] = breakdown.get(cls_name, 0) + 1
                confidences.append(conf)

                # Dibujar recuadro en imagen anotada
                x1, y1, x2, y2 = [int(c) for c in coords]
                color = (0, 165, 255) if cls_name == "fibra" else (0, 255, 0)
                cv2.rectangle(img_bgr, (x1, y1), (x2, y2), color, 2)
                cv2.putText(
                    img_bgr,
                    f"{cls_name} {conf:.2f}",
                    (x1, max(15, y1 - 8)),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.5,
                    color,
                    2,
                )

        total_particles = len(detections)
        avg_confidence = (
            round(sum(confidences) / len(confidences), 4)
            if confidences
            else 0.0
        )

        annotated_filename = f"annotated_{file_id}.jpg"
        annotated_path = self.static_dir / annotated_filename
        cv2.imwrite(str(annotated_path), img_bgr)

        elapsed_ms = round((time.perf_counter() - start_time) * 1000, 2)

        return AnalysisData(
            sample_id=sample_id,
            total_particles=total_particles,
            confidence=avg_confidence,
            breakdown=breakdown,
            detections=detections,
            processing_time_ms=elapsed_ms,
            annotated_image_url=f"/static/detections/{annotated_filename}",
        )


inference_service = InferenceService()
